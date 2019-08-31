__precompile__()

module BedgraphFiles

using FileIO
using Requires

using Bedgraph

using IteratorInterfaceExtensions, TableTraits, TableTraitsUtils
using TableShowUtils

import IterableTables


function __init__()
    @require DataFrames="a93c6f00-e57d-5684-b7b6-d8193f3e46c0" include(joinpath(@__DIR__, "integrations","DataFrames.jl")) 
end

const BedgraphFileFormat = File{format"bedGraph"}

struct BedgraphFile
    filename::String
    keywords
end

function Base.show(io::IO, source::BedgraphFile)
    TableShowUtils.printtable(io, getiterator(source), "bedGraph file")
end

function Base.read(file::BedgraphFile) :: Vector{Bedgraph.Record}
    # Read file using Bedgraph package.
    return open(file.filename, "r") do io
        Bedgraph.readRecords(io)
    end

end

function load(f::BedgraphFileFormat; args...)
    return BedgraphFile(f.filename, args)
end

IteratorInterfaceExtensions.isiterable(x::BedgraphFile) = true
TableTraits.isiterabletable(x::BedgraphFile) = true
IteratorInterfaceExtensions.isiterable(x::Vector{Bedgraph.Record}) = true #Note: Vector{Bedgraph.Record} is iterable by default.
TableTraits.isiterabletable(x::Vector{Bedgraph.Record}) = true

function IteratorInterfaceExtensions.getiterator(records::Vector{Bedgraph.Record})

    columns = [
        Bedgraph.chrom.(records),
        Bedgraph.first.(records),
        Bedgraph.last.(records),
        Bedgraph.value.(records)
    ]

    names = Symbol[:chrom, :first, :last, :value]

    it = TableTraitsUtils.create_tableiterator(columns, names)

    return it
end

function IteratorInterfaceExtensions.getiterator(file::BedgraphFile)

    records = read(file) #TODO: Generate iterator from first record?

    it = getiterator(records)

    return it
end

function Base.collect(x::BedgraphFile)
    return collect(getiterator(x))
end

function _Records(x) :: Vector{Bedgraph.Record} #TODO: consider formalising Records function in bedgraph (e.g. Bedgraph.Records, Bedgraph.Bedgraph.Records) that returns Vector{Bedgraph.Record}.
    cols, names = create_columns_from_iterabletable(x, na_representation=:missing)

    return convert(Vector{Bedgraph.Record}, cols[1], cols[2], cols[3], cols[4])
end

function Vector{Bedgraph.Record}(x::AbstractVector{T}) :: Vector{Bedgraph.Record} where {T<:NamedTuple}
    @debug "Vector{Bedgraph.Record}(x::AbstractVector{T})"
    return  _Records(x)
end

function Vector{Bedgraph.Record}(file::B) :: Vector{Bedgraph.Record} where {B<:BedgraphFile}
    @debug "Vector{Bedgraph.Record}(file::BedgraphFile)"
    return read(file)
end

function Vector{Bedgraph.Record}(x::T) :: Vector{Bedgraph.Record} where {T} #TODO: consider formalising Records function in bedgraph (e.g. Bedgraph.Records, Bedgraph.Bedgraph.Records) that returns Vector{Bedgraph.Record}.

    if TableTraits.isiterabletable(x)
        @debug "Vector{Bedgraph.Record}(x) - isiterabletable"
        return _Records(x)
    else
        @debug "Vector{Bedgraph.Record}(x) - converting"
        return convert(Vector{Bedgraph.Record}, x)
    end
end

function save(file::BedgraphFileFormat, header::Bedgraph.BedgraphHeader, records::Vector{Bedgraph.Record}) :: Vector{Bedgraph.Record}

    write(file.filename, header, records)

    return records #Note: this return is useful when piping (e.g., records = some_operation | save(file)).
end

function save(file::BedgraphFileFormat, records::Vector{Bedgraph.Record}; bump_forward = true) :: Vector{Bedgraph.Record}

    sort!(records)

    header = Bedgraph.generateBasicHeader(records, bump_forward = bump_forward) #TODO: consolidate header generation and determine whether there is a need for bump_forward.

    return save(file, header, records)
end

function save(file::BedgraphFileFormat, data; bump_forward = true)

    it = getiterator(data)

    records = Vector{Bedgraph.Record}(it)

    save(file, records, bump_forward = bump_forward)

    return data #Note: this return is usful when piping.
end

end # module
