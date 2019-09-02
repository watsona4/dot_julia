export RowGraph
#required methods
export getRowMap, getColMap, getDomainMap, getRangeMap, getImporter, getExporter
export getGlobalNumRows, getGlobalNumCols, getGlobalNumEntries, getGlobalNumDiags
export getLocalNumRows, getLocalNumCols, getLocalNumEntries, getLocalNumDiags
export getNumEntriesInGlobalRow, getNumEntriesInLocalRow
export getGlobalMaxNumRowEntries, getLocalMaxNumRowEntries
export hasColMap, isLowerTriangular, sUpperTriangular
export isLocallyIndexed, isGloballyIndexed, isFillComplete
export getGlobalRowCopy, getLocalRowCopy, pack
#implemented methods
export isFillActive


"""
RowGraph is the base "type" for all row oriented storage graphs

Instances of these types are required to implement the following submethods

    getRowMap(::RowGraph{GID, PID, LID})::BlockMap{GID, PID, LID}
Gets the row map for the graph

    getColMap(::RowGraph{GID, PID, LID})::BlockMap{GID, PID, LID}
Gets the column map for the graph

    getDomainMap(::RowGraph{GID, PID, LID})::BlockMap{GID, PID, LID}
Gets the domain map for the graph

    getRangeMap(::RowGraph{GID, PID, LID})::BlockMap{GID, PID, LID}
Gets the range map for the graph

    getImporter(::RowGraph{GID, PID, LID})::Union{Import{GID, PID, LID}, Nothing}
Gets the graph's Import object

    getExporter(::RowGraph{GID, PID, LID})::Union{Export{GID, PID, LID}, Nothing}
Gets the graph's Export object

    getGlobalNumEntries(::RowGraph{GID, PID, LID})::GID
Returns the global number of entries in the graph

    getLocalNumEntries(::RowGraph{GID, PID, LID})::LID
Returns the local number of entries in the graph

    getNumEntriesInLocalRow(::RowGraph{GID, PID, LID}, row::LID)::LID
Returns the current number of local entries in the given row

    getGlobalNumDiags(::RowGraph{GID, PID, LID})::GID
Returns the global number of diagonal entries

    getLocalNumDiags(::RowGraph{GID, PID, LID})::LID
Returns the local number of diagonal entries

    getGlobalMaxNumRowEntries(::RowGraph{GID, PID, LID})::LID
Returns the maximum number of entries across all rows/columns on all processors

    getLocalMaxNumRowEntries(::RowGraph{GID, PID, LID})::LID
Returns the maximum number of entries across all rows/columns on this processor

    hasColMap(::RowGraph{GID, PID, LID})::Bool
Whether the graph has a well-defined column map

    isLowerTriangular(::RowGraph{GID, PID, LID})::Bool
Whether the graph is lower trianguluar

    isUpperTriangular(::RowGraph{GID, PID, LID})::Bool
Whether the graph is upper trianguluar

    isGloballyIndexed(::RowGraph)::Bool
Whether the graph is using global indices

    isFillComplete(::RowGraph)
If the graph is fully build.

    getLocalRowCopy!(copy::AbstractVector{<:Integer}, graph::RowGraph{GID, PID, LID}, row::LID)::Integer
Copies the given row of the graph into the provided array using local indices


For optimal performance, the following methods may need to be re-implemented for the specific type
`getGlobalRowCopy!(copy::AbstractVector{<:Integer}, graph::RowGraph{GID}, row::GID)::Integer` is implemented by calling `getLocalRowCopy!` and remapping the values using `gid(::BlockMap, ::Integer)`

`getNumEntriesInGlobalRow(graph::RowGraph{GID, PID, LID}, row::GID)` is implemented using `getNumEntriesInLocalRow`

"""
abstract type RowGraph{GID <: Integer, PID <: Integer, LID <: Integer}
end

"""
    isFillActive(::RowGraph)

Whether the graph is being built
"""
isFillActive(graph::RowGraph) = !isFillComplete(graph)


"""
    getNumEntriesInLocalRow(::RowGraph{GID, PID, LID}, row::Integer)::LID

Returns the current number of local entries in the given row
"""
Base.@propagate_inbounds function getNumEntriesInLocalRow(graph::RowGraph{GID, PID, LID},
        row::Integer)::LID where{GID, PID, LID}
    getNumEntriesInLocalRow(graph, LID(row))
end

"""
    getGlobalRowCopy(graph::RowGraph{GID}, row::Integer)::AbstractVector{GID}

Creates a copy of the given row of the graph using global indices
"""
Base.@propagate_inbounds function getGlobalRowCopy(graph::RowGraph{GID}, row::Integer)::AbstractVector{GID} where GID
    numElts = getNumEntriesInGlobalRow(graph, row)
    copy = Vector{GID}(undef, numElts)
    getGlobalRowCopy!(copy, graph, GID(row))
    copy
end


"""
    getLocalRowCopy(graph::RowGraph{GID}, row::Integer)::AbstractVector{GID}

Creates a copy of the given row of the graph using local indices
"""
Base.@propagate_inbounds function getLocalRowCopy(graph::RowGraph{GID, PID, LID}, row::Integer)::AbstractVector{LID} where {GID, PID, LID}
    numElts = getNumEntriesInGlobalRow(graph, row)
    copy = Vector{LID}(undef, numElts)
    getLocalRowCopy!(copy, graph, LID(row))
    copy
end


"""
    getGlobalRowCopy!(copy::AbstractVector{GID}, graph::RowGraph{GID}, row::Integer)::Integer

Copies the given row of the graph into the provided array using global indices
"""
Base.@propagate_inbounds function getGlobalRowCopy!(copy::AbstractVector{<:Integer}, graph::RowGraph{GID},
        row::Integer)::Integer where GID
    getGlobalRowCopy!(graph, GID(row))
end

Base.@propagate_inbounds function getGlobalRowCopy!(copy::AbstractVector{<:Integer},
            matrix::RowGraph{GID}, globalRow::GID) where {GID}
    rowMap = getRowMap(matrix)
    numElts = getLocalRowCopy!(copy, matrix, lid(rowMap, globalRow))
    @. copy = gid(rowMap, copy)
    numElts
end

"""
    getLocalRowCopy!(copy::AbstractVector{<:Integer}, graph::RowGraph{GID, PID, LID}, row::Integer)::Integer

Copies the given row of the graph into the provided array using global indices
"""
Base.@propagate_inbounds function getLocalRowCopy!(copy::AbstractVector{<:Integer}, graph::RowGraph{GID, PID, LID},
        row::Integer)::Integer where {GID, PID, LID}
    getLocalRowCopy!(graph, LID(row))
end


"""
    isLocallyIndexed(::RowGraph)::Bool

Whether the graph is using local indices.

The default implementation uses the row graph
"""
isLocallyIndexed(graph::RowGraph) = !isGloballyIndexed(graph)


"""
    getGlobalNumRows(::RowGraph{GID})::GID

Returns the number of global rows in the graph

The default implementation uses the row graph
"""
getGlobalNumRows(graph::RowGraph) = numAllElements(getRowMap(graph))

"""
    getGlobalNumCols(::RowGraph{GID})::GID

Returns the number of global columns in the graph

The default implementation uses the row graph
"""
getGlobalNumCols(graph::RowGraph) = numAllElements(getColMap(graph))

"""
    getLocalNumRows(::RowGraph{GID, PID, LID})::LID

Returns the number of rows owned by the calling process

The default implementation uses the row graph
"""
getLocalNumRows(graph::RowGraph) = numMyElements(getRowMap(graph))

"""
    getLocalNumCols(::RowGraph{GID, PID, LID})::LID

Returns the number of columns owned by the calling process

The default implementation uses the row graph
"""
getLocalNumCols(graph::RowGraph) = nulMyElements(getColMap(graph))

"""
    getNumEntriesInGlobalRow(graph::RowGraph{GID, PID, LID}, row::Integer)::LID

Returns the current number of local entries in the given row
"""
function getNumEntriesInGlobalRow(graph::RowGraph{GID, PID, LID}, row::Integer
        )::LID where {GID, PID, LID}
    getNumEntriesInGlobalRow(graph, row::GID)
end

function getNumEntriesInGlobalRow(graph::RowGraph{GID, PID, LID}, row::GID
        )::LID where {GID, PID, LID}
    getNumEntriesInLocalRow(graph, lid(getRowMap(graph), row))
end

"""
    pack(::RowGraph{GID, PID, LID}, exportLIDs::AbstractArray{LID, 1}, distor::Distributor{GID, PID, LID})::AbstractArray{AbstractArray{LID, 1}}

Packs this object's data for import or export
"""
function pack(source::RowGraph{GID, PID, LID}, exportLIDs::AbstractArray{LID, 1}, distor::Distributor{GID, PID, LID})::Array{Array{LID, 1}, 1} where {GID, PID, LID}
    srcMap = getMap(source)
    map(lid->getGlobalRowCopy(source, gid(srcMap, lid)), exportLIDs)
end

#### SrcDistObject methods ####
getMap(graph::RowGraph) = getRowMap(graph)

#### documentation for required methods ####

"""
    isFillComplete(mat::RowGraph)

Whether `fillComplete(...)` has been called
"""
function isFillComplete end

"""
    getRowMap(::RowGraph{GID, PID, LID})::BlockMap{GID, PID, LID}

Gets the row map for the graph
"""
function getRowMap end

"""
    getColMap(::RowGraph{GID, PID, LID})::BlockMap{GID, PID, LID}

Gets the column map for the graph
"""
function getColMap end

"""
    hasColMap(::RowGraph{GID, PID, LID})::Bool

Whether the graph has a well-defined column map
"""
function hasColMap end

"""
    getDomainMap(::RowGraph{GID, PID, LID})::BlockMap{GID, PID, LID}

Gets the domain map for the graph
"""
function getDomainMap end

"""
    getRangeMap(::RowGraph{GID, PID, LID})::BlockMap{GID, PID, LID}

Gets the range map for the graph
"""
function getRangeMap end

"""
    getImporter(::RowGraph{GID, PID, LID})::Union{Import{GID, PID, LID}, Nothing}

Gets the graph's Import object, or null if the import is trivial
"""
function getImporter end

"""
    getExporter(::RowGraph{GID, PID, LID})::Union{Export{GID, PID, LID}, Nothing}

Gets the graph's Export object, or null if the export is trivial
"""
function getExporter end

"""
    getGlobalNumEntries(::RowGraph{GID, PID, LID})::GID

Returns the global number of entries in the graph
"""
function getGlobalNumEntries end

"""
    getLocalNumEntries(::RowGraph{GID, PID, LID})::LID

Returns the local number of entries in the graph
"""
function getLocalNumEntries end

"""
    getNumEntriesInLocalRow(::RowGraph{GID, PID, LID}, row::LID)::LID

Returns the current number of local entries in the given row
"""
function getNumEntriesInLocalRow end

"""
    getGlobalNumDiags(::RowGraph{GID, PID, LID})::GID

Returns the global number of diagonal entries
"""
function getGlobalNumDiags end

"""
    getLocalNumDiags(::RowGraph{GID, PID, LID})::LID

Returns the local number of diagonal entries
"""
function getLocalNumDiags end

"""
    getGlobalMaxNumRowEntries(::RowGraph{GID, PID, LID})::LID

Returns the maximum number of entries across all rows/columns on all processors
"""
function getGlobalMaxNumRowEntries end

"""
    getLocalMaxNumRowEntries(::RowGraph{GID, PID, LID})::LID

Returns the maximum number of entries across all rows/columns on the calling processor
"""
function getLocalMaxNumRowEntries end

"""
    isLowerTriangular(::RowGraph{GID, PID, LID})::Bool

Whether the graph is lower trianguluar
"""
function isLowerTriangular end

"""
    isUpperTriangular(::RowGraph{GID, PID, LID})::Bool

Whether the graph is upper trianguluar
"""
function isUpperTriangular end

"""
    isGloballyIndexed(::RowGraph)::Bool

Whether the graph is using global indices
"""
function isGloballyIndexed end
