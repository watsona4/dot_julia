export LocalCSRGraph, numRows, maxEntry, minEntry

"""
    LocalCSRGraph{EntriesType, IndexType}()
    LocalCSRGraph(entries::AbstractArray{EntriesType, 1}, rowMap::AbstractArray{IndexType, 1})

A compressed row storage array.  Used by CSRGraph to store local structure.
`EntriesType` is the type of the data being held
`IndexType` is the type used to represent the indices
"""
mutable struct LocalCSRGraph{EntriesType, IndexType <: Integer}
    entries::AbstractArray{EntriesType, 1}
    rowMap::AbstractArray{IndexType, 1}
end

function LocalCSRGraph{EntriesType, IndexType}() where{EntriesType, IndexType <: Integer}
    LocalCSRGraph(Array{EntriesType, 1}(undef, 0), Array{IndexType, 1}(undef, 0))
end


"""
    numRows(::LocalCSRGraph{EntriesType, IndexType})::IndexType

Gets the number of rows in the storage
"""
function numRows(graph::LocalCSRGraph{EntriesType, IndexType})::IndexType where {
        EntriesType, IndexType <: Integer}
    len = length(graph.rowMap)
    if len != 0
        len - 1
    else
        0
    end
end

"""
    maxEntry(::LocalCSRGraph{EntriesType})::EntriesType

Finds the entry with the maximum value.
"""
function maxEntry(graph::LocalCSRGraph{EntriesType})::EntriesType where {
        EntriesType}
    if length(graph.entries) != 0
        maximum(graph.entries)
    else
        throw(InvalidArgumentError("Cannot find the maximum of an empty graph"))
    end
end

"""
    minEntry(::LocalCSRGraph{EntriesType})::EntriesType

Finds the entry with the minimum value.
"""
function minEntry(graph::LocalCSRGraph{EntriesType})::EntriesType where {
        EntriesType}
    if length(graph.entries) != 0
        minimum(graph.entries)
    else
        throw(InvalidArgumentError("Cannot find the minimum of an empty graph"))
    end
end
