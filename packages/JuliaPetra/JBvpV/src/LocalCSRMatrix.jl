export LocalCSRMatrix, numRows, numCols, getRowView

struct LocalCSRMatrix{Data, IndexType <: Integer}
    graph::LocalCSRGraph{IndexType, IndexType}
    values::Union{Vector{Data}, SubArray{Data, 1, Vector{Data}, Tuple{UnitRange{IndexType}}, true}}

    numCols::IndexType
end

"""
    LocalCSRMatrix{Data, IndexType}()

Creates an empty LocalCSRMatrix
"""
function LocalCSRMatrix{Data, IndexType}() where {Data, IndexType}
    LocalCSRMatrix(LocalCSRGraph{IndexType, IndexType}(), Data[], IndexType(0))
end

"""
    LocalCSRMatrix(nRows::Integer, nCols::Integer, vals::AbstractArray{Data, 1}, rows::AbstractArray{IndexType, 1}, cols::AbstractArray{IndexType, 1}}

Creates the specified LocalCSRMatrix
"""
function LocalCSRMatrix(nRows::Integer, nCols::Integer,
        vals::AbstractArray{Data, 1}, rows::AbstractArray{IndexType, 1},
        cols::AbstractArray{IndexType, 1}) where {Data, IndexType}
    if length(rows) != nRows + 1
        throw(InvalidArgumentError("length(rows) = $(length(rows)) != nRows+1 "
                * "= $(nRows + 1)"))
    end
    LocalCSRMatrix(LocalCSRGraph(cols, rows), vals, IndexType(nCols))
end

"""
    LocalCSRMatrix(numCols::IndexType, values::AbstractArray{Data, 1}, localGraph::LocalCSRGraph{IndexType, IndexType}) where {IndexType, Data <: Number}

Creates the specified LocalCSRMatrix
"""
function LocalCSRMatrix(numCols::IndexType, values::AbstractArray{Data, 1},
        localGraph::LocalCSRGraph{IndexType, IndexType}) where {IndexType, Data <: Number}
    if numCols < 0
        throw(InvalidArgumentError("Cannot have a negative number of rows"))
    end

    LocalCSRMatrix(localGraph, values, numCols)
end


"""
    numRows(::LocalCSRMatrix{Data, IndexType})::IndexType

Gets the number of rows in the matrix
"""
numRows(matrix::LocalCSRMatrix) = numRows(matrix.graph)

"""
    numCols(::LocalCSRMatrix{Data, IndexType})::IndexType

Gets the number of columns in the matrix
"""
numCols(matrix::LocalCSRMatrix) = matrix.numCols

"""
    getRowView((matrix::LocalCSRMatrix{Data, IndexType}, row::Integer)::SparseRowView{Data, IndexType}

Gets a view of the requested row
"""
function getRowView(matrix::LocalCSRMatrix{Data, IndexType},
        row::Integer)::SparseRowView{Data, IndexType} where {Data, IndexType}
    start = matrix.graph.rowMap[row]
    count = matrix.graph.rowMap[row+1] - start

    if count == 0
        SparseRowView(Data[], IndexType[])
    else
        SparseRowView(matrix.values, matrix.graph.entries, count, start)
    end
end
