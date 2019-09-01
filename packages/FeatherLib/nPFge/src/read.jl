struct ResultSet
    columns::AbstractVector{AbstractVector}
    names::Vector{Symbol}
    description::String
    metadata::String
end

function featherread(filename::AbstractString; use_mmap=true)
    data = loadfile(filename, use_mmap=use_mmap)
    ctable = getctable(data)
    ncols = length(ctable.columns)
    colnames = [Symbol(col.name) for col in ctable.columns]
    coltypes = [juliatype(col) for col in ctable.columns]
    columns = ArrowVector[constructcolumn(coltypes[i], data, ctable.columns[i].metadata, ctable.columns[i]) for i in 1:ncols]
    return ResultSet(columns, colnames, ctable.description, ctable.metadata)
end

#=====================================================================================================
    new column construction stuff
=====================================================================================================#
Base.length(p::Metadata.PrimitiveArray) = p.length

startloc(p::Metadata.PrimitiveArray) = p.offset+1

Arrow.nullcount(p::Metadata.PrimitiveArray) = p.null_count

function bitmasklength(p::Metadata.PrimitiveArray)
    nullcount(p) == 0 ? 0 : padding(bytesforbits(length(p)))
end

function offsetslength(p::Metadata.PrimitiveArray)
    isprimitivetype(p.dtype) ? 0 : padding((length(p)+1)*sizeof(Int32))
end

valueslength(p::Metadata.PrimitiveArray) = p.total_bytes - offsetslength(p) - bitmasklength(p)

function offsetsloc(p::Metadata.PrimitiveArray)
    if isprimitivetype(p.dtype)
        throw(ErrorException("Trying to obtain offset values for primitive array."))
    end
    startloc(p) + bitmasklength(p)
end

# override default offset type
Locate.Offsets(col::Metadata.PrimitiveArray) = Locate.Offsets{Int32}(offsetsloc(col))

Locate.length(col::Metadata.PrimitiveArray) = length(col)
Locate.values(col::Metadata.PrimitiveArray) = startloc(col) + bitmasklength(col) + offsetslength(col)
# this is only relevant for lists, values type must be UInt8
Locate.valueslength(col::Metadata.PrimitiveArray) = valueslength(col)
Locate.bitmask(col::Metadata.PrimitiveArray) = startloc(col)

function constructcolumn(::Type{T}, data::Vector{UInt8}, meta::Metadata.CategoryMetadata, col::Metadata.Column) where T
    reftype = juliatype(col.values.dtype)
    DictEncoding{T}(locate(data, reftype, col.values), locate(data, T, col.metadata.levels))
end

function constructcolumn(::Type{Union{T,Missing}}, data::Vector{UInt8}, meta::Metadata.CategoryMetadata, col::Metadata.Column) where T
    reftype = Union{juliatype(col.values.dtype),Missing}
    DictEncoding{Union{T,Missing}}(locate(data, reftype, col.values), locate(data, T, col.metadata.levels))
end

function constructcolumn(::Type{T}, data::Vector{UInt8}, meta, col::Metadata.Column) where T
    locate(data, T, col.values)
end
