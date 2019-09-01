# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMSparse.jl/blob/master/LICENSE

mutable struct SparseMatrixCOO{Tv,Ti<:Integer} <: AbstractSparseMatrix{Tv,Ti}
    I :: Vector{Ti}
    J :: Vector{Ti}
    V :: Vector{Tv}
end

SparseMatrixCOO() = SparseMatrixCOO(Int[], Int[], Float64[])
SparseMatrixCOO(A::SparseMatrixCSC{Tv,Ti}) where {Tv, Ti<:Integer} = SparseMatrixCOO(findnz(A)...)
SparseMatrixCOO(A::Matrix) = SparseMatrixCOO(sparse(A))
SparseArrays.SparseMatrixCSC(A::SparseMatrixCOO) = sparse(A.I, A.J, A.V)
Base.isempty(A::SparseMatrixCOO) = isempty(A.I) && isempty(A.J) && isempty(A.V)
Base.size(A::SparseMatrixCOO) = isempty(A) ? (0, 0) : (maximum(A.I), maximum(A.J))
Base.size(A::SparseMatrixCOO, idx::Int) = size(A)[idx]
Base.Matrix(A::SparseMatrixCOO) = Matrix(SparseMatrixCSC(A))

get_nonzero_rows(A::SparseMatrixCOO) = unique(A.I[findall(!iszero, A.V)])
get_nonzero_columns(A::SparseMatrixCOO) = unique(A.J[findall(!iszero, A.V)])

function Base.getindex(A::SparseMatrixCOO{Tv, Ti}, i::Ti, j::Ti) where {Tv, Ti}
    if length(A.V) > 1_000_000
        @warn("Performance warning: indexing of COO sparse matrix is slow.")
    end
    p = (A.I .== i) .& (A.J .== j)
    return sum(A.V[p])
end

"""
    add!(A, i, j, v)

Add new value to sparse matrix `A` to location (`i`,`j`).
"""
function add!(A::SparseMatrixCOO, i, j, v)
    push!(A.I, i)
    push!(A.J, j)
    push!(A.V, v)
    return nothing
end

function Base.empty!(A::SparseMatrixCOO)
    empty!(A.I)
    empty!(A.J)
    empty!(A.V)
    return nothing
end

"""
    assemble!(K, dofs1, dofs2, Ke)

Assemble a local dense element matrix `Ke` to a global sparse matrix `K`, to the
location given by lists of indices `dofs1` and `dofs2`.

# Example

```julia
dofs1 = [3, 4]
dofs2 = [6, 7, 8]
Ke = [5.0 6.0 7.0; 8.0 9.0 10.0]
K = SparseMatrixCOO()
assemble!(K, dofs1, dofs2, Ke)
Matrix(K)

# output

4x8 Array{Float64,2}:
 0.0  0.0  0.0  0.0  0.0  0.0  0.0   0.0
 0.0  0.0  0.0  0.0  0.0  0.0  0.0   0.0
 0.0  0.0  0.0  0.0  0.0  5.0  6.0   7.0
 0.0  0.0  0.0  0.0  0.0  8.0  9.0  10.0
```
"""
function assemble_local_matrix!(A::SparseMatrixCOO, dofs1::AbstractVector{Int}, dofs2::AbstractVector{Int}, data)
    n, m = length(dofs1), length(dofs2)
    @assert length(data) == n*m
    k = 1
    for j=1:m
        for i=1:n
            add!(A, dofs1[i], dofs2[j], data[k])
            k += 1
        end
    end
    return nothing
end

function add!(A::SparseMatrixCOO, dofs1::AbstractVector{Int}, dofs2::AbstractVector{Int}, data)
    assemble_local_matrix!(A, dofs1, dofs2, data)
end
