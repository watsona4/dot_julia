#####
##### Read Stata DTA files using a row-wise interface, via Tables
#####

module StataDTAFiles

using ArgCheck: @argcheck
import Dates
using DocStringExtensions: SIGNATURES, TYPEDEF
using Parameters: @unpack
using StrFs: StrF
import Tables

import Base: read, seek, iterate, length, open, close, eltype, show

export DTAFile, elapsed_days

####
#### types for byteorder handling and IO wrapper
####

abstract type ByteOrder end

struct MSF <: ByteOrder end     # big-endian

struct LSF <: ByteOrder end     # little-endian

struct ByteOrderIO{B <: ByteOrder, T <: IO} <: IO
    byteorder::B
    io::T
end

read(io::ByteOrderIO, ::Type{UInt8}) = read(io.io, UInt8)

seek(io::ByteOrderIO, pos) = seek(io.io, pos)

####
#### tag verification
####

function verifytag(io::IO, tag::AbstractArray{UInt8}, closing::Bool = false)
    read(io, UInt8) == UInt8('<') || error("First byte is not a '<'.")
    if closing
        read(io, UInt8) == UInt8('/') || error("/ expected (closing tag).")
    end
    for c in tag
        read(io, UInt8) == c || error("not the expected tag.")
    end
    read(io, UInt8) == UInt8('>') || error("Tag not closed with '>'.")
    nothing
end

verifytag(io::IO, tag::String, closing::Bool = false) = verifytag(io, codeunits(tag), closing)

function verifytag(f::Function, io::IO, tag)
    verifytag(io, tag)
    result = f(io)
    verifytag(io, tag, true)
    result
end

####
#### reading primitives
####

readfixedstring(io::IO, nb) = String(read!(io, Vector{UInt8}(undef, nb)))

function readbyteorder(io::IO)
    verifytag(io, "byteorder") do io
        order = readfixedstring(io, 3)
        if order == "MSF"
            MSF()
        elseif order == "LSF"
            LSF()
        else
            error("unknown byte order $(order)")
        end
    end
end

"""
Number types is Stata that correspond to native Julia types, and are denoted by the latter.
"""
const DATANUMTYPES = Union{Int8, Int16, Int32, Float32, Float64}

"""
Number types which are read by `readnum`, in addition to `DATANUMTYPES`.
"""
const EXTRANUMTYPES = Union{Int64, UInt8, UInt16, UInt32, UInt64}

"""
All number types read by `readnum`.
"""
const READNUMTYPES = Union{DATANUMTYPES, EXTRANUMTYPES}

readnum(boio::ByteOrderIO{MSF}, T::Type{<:READNUMTYPES}) = ntoh(read(boio.io, T))

readnum(boio::ByteOrderIO{LSF}, T::Type{<:READNUMTYPES}) = ltoh(read(boio.io, T))

"""
$(SIGNATURES)

Read chars into a buffer of length `len`, find the terminating "\0" (if any) and truncate,
returning a string.
"""
function readchompedstring(boio::ByteOrderIO, len::Integer)
    buffer = Vector{UInt8}(undef, len)
    read!(boio.io, buffer)
    numchars = findfirst(isequal(0x00), buffer)
    if numchars ≢ nothing
        resize!(buffer, numchars - 1)
    end
    String(buffer)
end

"""
$(SIGNATURES)

Read length (of type T), then read and chomp the string.
"""
function readchompedstring(boio::ByteOrderIO, T::Type{<:Integer})
    len = Int(readnum(boio, T))
    readchompedstring(boio, len)
end

####
#### header
####

"""
$(TYPEDEF)

DTA file header (without the byte order, which is encoded in the corresponding
`ByteOrderIO`.
"""
struct DTAHeader
    release::Int
    variables::Int
    observations::Int
    label::String
    timestamp::Dates.DateTime
end

"Date format of Stata file timestamps."
const TIMESTAMPFMT = Dates.DateFormat("d u y H:M") # eg 04 Jul 2032 04:23

function read_header(io::IO)
    verifytag(io, "header") do io
        @assert verifytag(io -> readfixedstring(io, 3), io, "release") == "118"
        byteorder = readbyteorder(io)
        boio = ByteOrderIO(byteorder, io)
        K = verifytag(boio -> readnum(boio, Int16), boio, "K")
        N = verifytag(boio -> readnum(boio, Int64), boio, "N")
        label = verifytag(boio -> readchompedstring(boio, Int16), boio, "label")
        timestamp_str = strip(verifytag(boio -> readchompedstring(boio, Int8), boio, "timestamp"))
        timestamp = Dates.DateTime(timestamp_str, TIMESTAMPFMT)
        DTAHeader(118, Int(K), Int(N), label, timestamp), boio
    end
end

####
#### map
####

struct DTAMap
    stata_data_open::Int64
    map::Int64
    variable_types::Int64
    varnames::Int64
    sortlist::Int64
    formats::Int64
    value_label_names::Int64
    variable_labels::Int64
    characteristics::Int64
    data::Int64
    strls::Int64
    value_labels::Int64
    stata_data_close::Int64
    eof::Int64
end

function read_map(boio::ByteOrderIO)
    verifytag(boio, "map") do boio
        map = DTAMap([readnum(boio, Int64) for _ in 1:14]...)
        @assert map.stata_data_open == 0
        map
    end
end

####
#### types
####

"""
Maximum length of `str#` (aka `strfs`) strings in Stata DTA files.
"""
const STRFSMAXLEN = 2045

"""
$(SIGNATURES)

Map the numerical type code in a DTA file to a Julia type.

Note that numeric types use a sentinel for missing values, and thus are decoded as
`Union{Missing, T}` for the corresponding type `T`.
"""
function decode_variable_type(code::UInt16)
    if 1 ≤ code ≤ STRFSMAXLEN
        StrF{Int(code)}
    elseif code == 32768
        String
    elseif 65526 ≤ code ≤ 65530
        Union{Missing, (Float64, Float32, Int32, Int16, Int8)[code - 65525]}
    else
        error("unrecognized variable type code $(code)")
    end
end

"""
$(SIGNATURES)

Read variable types from a DTA file. Return a tuple of Julia types.
"""
function read_variable_types(boio::ByteOrderIO, header::DTAHeader, map::DTAMap)
    seek(boio, map.variable_types)
    verifytag(boio, "variable_types") do boio
        ((decode_variable_type(readnum(boio, UInt16)) for _ in 1:header.variables)..., )
    end
end

####
#### metadata
####

"""
$(SIGNATURES)

Read variable names, returning a tuple of `Symbol`s.
"""
function read_variable_names(boio::ByteOrderIO, header::DTAHeader, map::DTAMap)
    seek(boio, map.varnames)
    verifytag(boio, "varnames") do boio
        ntuple(_ -> Symbol(readchompedstring(boio, 129)), header.variables)
    end
end

"""
$(SIGNATURES)

Read the sortlist, a vector if integers which contains column indexes for nested sorting.
"""
function read_sortlist(boio::ByteOrderIO, header::DTAHeader, map::DTAMap)
    seek(boio, map.sortlist)
    verifytag(boio, "sortlist") do boio
        sortlist = [readnum(boio, Int16) for _ in 1:(header.variables + 1)]
        terminator = findfirst(iszero, sortlist)
        @assert terminator ≢ nothing
        sortlist[1:(terminator-1)]
    end
end

"""
$(SIGNATURES)

Read the format strings, returning a `Vector{String}`.
"""
function read_formats(boio::ByteOrderIO, header::DTAHeader, map::DTAMap)
    seek(boio, map.formats)
    verifytag(boio, "formats") do boio
        [readchompedstring(boio, 57) for _ in 1:header.variables]
    end
end

####
#### read data
####

const MAXINT8 = Int8(0x64)
const MAXINT16 = Int16(0x7fe4)
const MAXINT32 = Int32(0x7fffffe5)
const MAXFLOAT32 = Float32(0x1.fffffep126)
const MAXFLOAT64 = Float64(0x1.fffffffffffffp1022)

decode_missing(x::Int8) = x ≥ MAXINT8 ? missing : x
decode_missing(x::Int16) = x ≥ MAXINT16 ? missing : x
decode_missing(x::Int32) = x ≥ MAXINT32 ? missing : x
decode_missing(x::Float32) = x ≥ MAXFLOAT32 ? missing : x
decode_missing(x::Float64) = x ≥ MAXFLOAT64 ? missing : x

readfield(boio::ByteOrderIO, ::Type{Union{Missing,T}}) where T =
    decode_missing(read(boio, T))

readfield(boio::ByteOrderIO, ::Type{StrF{N}}) where N = read(boio, StrF{N})

_readrow(boio::ByteOrderIO, ::Type{Tuple{}}) = ()

_readrow(boio::ByteOrderIO, ::Type{T}) where T <: Tuple =
    (readfield(boio, Base.tuple_type_head(T)), _readrow(boio, Base.tuple_type_tail(T))...)

# NOTE: type assertion below is needed because of
# https://github.com/JuliaLang/julia/issues/29970
# TODO: revisit once that improves
readrow(boio::ByteOrderIO, ::Type{NamedTuple{N,T}}) where {N,T} =
    NamedTuple{N,T}(_readrow(boio, T))::NamedTuple{N,T}

####
#### API
####

"""
$(TYPEDEF)

Representation of a Stata DTA file for which everything except the data itself has been read.

The data (rows) can be read as `NamedTuple`s, using the iteration interface.
"""
struct DTAFile{T <: NamedTuple, B <: ByteOrderIO}
    boio::B
    header::DTAHeader
    map::DTAMap
    sortlist::Vector{Int16}
    formats::Vector{String}
end

function show(io::IO, dta::DTAFile{T}) where T
    @unpack header, sortlist, formats = dta
    @unpack release, variables, observations, label, timestamp = header
    COLORHEADER = :red
    COLORVAR = :blue
    COLORTYPE = :green
    print(io, "Stata DTA file $(release), ")
    printstyled(io, "$(variables) vars"; color = COLORHEADER)
    print(io, " in ")
    printstyled(io, "$(observations) rows"; color = COLORHEADER)
    println(io, ", ", timestamp)
    isempty(label) || println(io, "    label: ", label)
    varnames = fieldnames(T)
    if isempty(sortlist)
        println(io, "    not sorted")
    else
        print(io, "    sorted by ")
        printstyled(io, varnames[sortlist], "\n"; color = COLORVAR)
    end
    for (i, (varname, format)) in enumerate(zip(varnames, formats))
        i == 1 || println(io)
        print(io, "  ")
        printstyled(io, varname; color = COLORVAR)
        print(io, "::")
        printstyled(io, fieldtype(T, varname); color = COLORTYPE)
        print(io, " [", format, "]")
    end
end

open(::Type{DTAFile}, path::AbstractString) = open(DTAFile, open(path, "r"))

function open(::Type{DTAFile}, io::IO)
    seekstart(io)
    verifytag(io, "stata_dta")
    # read header and map
    header, boio = read_header(io)
    map = read_map(boio)
    # read the rest using map
    variable_names = read_variable_names(boio, header, map)
    sortlist = read_sortlist(boio, header, map)
    formats = read_formats(boio, header, map)
    variable_types = read_variable_types(boio, header, map)
    DTAFile{NamedTuple{variable_names, Tuple{variable_types...}},
            typeof(boio)}(boio, header, map, sortlist, formats)
end

function open(f::Function, ::Type{DTAFile}, args...)
    dta = open(DTAFile, args...)
    try
        f(dta)
    finally
        close(dta)
    end
end

close(dta::DTAFile) = close(dta.boio.io)

####
#### row iteration interface
####

eltype(::Type{<: DTAFile{T}}) where T = T

length(dta::DTAFile) = dta.header.observations

function iterate(dta::DTAFile{T}, index = 1) where T
    @unpack boio = dta
    if index > dta.header.observations
        nothing
    else
        if index == 1
            seek(boio, dta.map.data)
            verifytag(boio, "data")
        end
        readrow(boio, T), index + 1
    end
end

####
#### Tables interface
####

Tables.istable(::Type{<:DTAFile}) = true

Tables.rowaccess(::Type{<:DTAFile}) = true

Tables.rows(dta::DTAFile) = dta

function Tables.schema(dta::DTAFile{NamedTuple{names, types}}) where {names, types}
    Tables.Schema(names, types)
end

####
#### date
####

"""
Start of the epoch, ie "day 0" for most date handling functions in Stata.

!!! note
    Don't use directly, see [`elapsed_days`](@ref).
"""
const EPOCH = Dates.Date(1960, 1, 1)

"""
$(SIGNATURES)

Convert a Stata "elapsed date" representation into `Date`.

Corresponds to the `%td` format in Stata.
"""
elapsed_days(Δ::Integer) = EPOCH + Dates.Day(Δ)

elapsed_days(Δ::Real) = elapsed_days(convert(Int, Δ))

end # module
