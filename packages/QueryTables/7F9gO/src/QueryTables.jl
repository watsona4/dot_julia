module QueryTables

import TableShowUtils, TableTraitsUtils

using DataValues

export DataTable, NA, isna

struct DataTable{T, TCOLS} <: AbstractVector{T}
    columns::TCOLS
end

function fromNT(nt)
    tx = typeof(nt)
    et = NamedTuple{propertynames(nt), Tuple{(eltype(fieldtype(tx, i)) for i in 1:fieldcount(typeof(nt)))...}}
    return DataTable{et, typeof(nt)}(nt)
end

swap_dva_in(A) = A
swap_dva_in(A::Array{<:DataValue}) = DataValueArray(A)

function DataTable(;cols...)
    return fromNT(map(col -> swap_dva_in(col), values(cols)))
end

function DataTable(table)
    cols, colnames = TableTraitsUtils.create_columns_from_iterabletable(table)

    return fromNT(NamedTuple{tuple(colnames...)}(tuple(cols...)))
end

columns(dt::DataTable) = getfield(dt, :columns)

@inline Base.getproperty(dt::DataTable, name::Symbol) = getproperty(columns(dt), name)

Base.size(dt::DataTable) = size(columns(dt)[1])

Base.IndexStyle(::Type{DataTable}) = Base.IndexLinear()

function Base.checkbounds(::Type{Bool}, dt::DataTable, i)
    cols = columns(dt)
    if length(cols)==0
        return true
    else
        return checkbounds(Bool, cols[1], i)
    end
end

@inline function Base.getindex(dt::DataTable{T}, i::Int) where {T}
    @boundscheck checkbounds(dt, i)
    return map(col -> @inbounds(getindex(col, i)), columns(dt))
end

function Base.show(io::IO, dt::DataTable)
    TableShowUtils.printtable(io, dt, "DataTable")
end

function Base.show(io::IO, ::MIME"text/plain", dt::DataTable)
    TableShowUtils.printtable(io, dt, "DataTable")
end

function Base.show(io::IO, ::MIME"text/html", dt::DataTable)
    TableShowUtils.printHTMLtable(io, dt)
end

Base.showable(::MIME"text/html", dt::DataTable) = true

function Base.show(io::IO, ::MIME"application/vnd.dataresource+json", dt::DataTable)
    TableShowUtils.printdataresource(io, dt)
end

Base.showable(::MIME"application/vnd.dataresource+json", dt::DataTable) = true

end
