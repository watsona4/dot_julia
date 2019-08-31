module BlockDiagonalFactors

using SparseArrays, SuiteSparse, LinearAlgebra

struct SparseBlockFactors{Tv}
    factors::Vector
    indices::Vector{<:Int}
    m::Int
    n::Int
end
struct BlockFactors{Tv}
    factors::Vector
    indices::Vector{<:Int}
    m::Int
    n::Int
end
export BlockFactors, SparseBlockFactors

# Factorization functions
for f in (:lu, :qr, :cholesky, :factorize), T in (:Float64, :(Complex{Float64}))
    @eval begin
        import LinearAlgebra: $f
        """
        $($f)(As::Vector{SparseMatrixCSC{$($T),Int}}, I::Vector{Int})

        Creates a block-diagonal (lazy) array of factors.
        Invokes `$($f)` on each matrix in the array of matrices `As` and stores them along with the indices `I`.
        """
        function $f(As::Vector{SparseMatrixCSC{$T,Int}}, I::Vector{Int})
            m = sum(i -> As[i].m, I)
            n = sum(i -> As[i].n, I)
            return SparseBlockFactors{$T}(map($f, As), I, m, n)
        end
        """
        $($f)(As::Vector{Array{$($T),2}}, I::Vector{Int})

        Creates a block-diagonal (lazy) array of factors.
        Invokes `$($f)` on each matrix in the array of matrices `As` and stores them along with the indices `I`.
        """
        function $f(As::Vector{Array{$T,2}}, I::Vector{Int})
            m = sum(i -> size(As[i],1), I)
            n = sum(i -> size(As[i],2), I)
            return BlockFactors{$T}(map($f, As), I, m, n)
        end
        export $f
    end
end

# TODO replace with lazy version? not sure how to do this
for f in (:adjoint, :transpose), TF in (:SparseBlockFactors, :BlockFactors), T in (:Float64, :(Complex{Float64}))
    @eval begin
        import Base: $f
        """
        $($f)(BDF::$($T))

        Invokes `$($f)` on all the factors in `BDF` and returns them into a new `$($T)` object.
        """
        $f(BDF::$TF{$T}) = $TF{$T}(map($f, BDF.factors), BDF.indices, BDF.m, BDF.n)
        export $f
    end
end

import Base.\
"""
    \\(BDF::SparseBlockFactors, y::AbstractVecOrMat)

Backsubstitution for `SparseBlockFactors`.
"""
function \(BDF::SparseBlockFactors{T}, y::AbstractVector{S}) where {T,S}
    x = Array{promote_type(T,S)}(undef, BDF.n)
    x_idx, y_idx = 0:0, 0:0
    my = size(y)[1]
    for i in BDF.indices
        x_idx = x_idx.stop .+ (1:size(BDF.factors[i],2))
        y_idx = y_idx.stop .+ (1:size(BDF.factors[i],1))
        x[x_idx] .= BDF.factors[i] \ y[y_idx]
    end
    return x
end
function \(BDF::SparseBlockFactors{T}, y::AbstractVector{T}) where T
    x = Array{T}(undef, BDF.n)
    x_idx, y_idx = 0:0, 0:0
    my = size(y)[1]
    for i in BDF.indices
        x_idx = x_idx.stop .+ (1:size(BDF.factors[i],2))
        y_idx = y_idx.stop .+ (1:size(BDF.factors[i],1))
        x[x_idx] .= BDF.factors[i] \ y[y_idx]
    end
    return x
end
"""
    \\(BDF::BlockFactors, y::AbstractVecOrMat)

Backsubstitution for `BlockFactors`.
"""
function \(BDF::BlockFactors{T}, y::AbstractVector{S}) where {T,S}
    x = Array{promote_type(T,S)}(undef, BDF.n)
    x_idx, y_idx = 0:0, 0:0
    my = size(y)[1]
    for i in BDF.indices
        x_idx = x_idx.stop .+ (1:size(BDF.factors[i],2))
        y_idx = y_idx.stop .+ (1:size(BDF.factors[i],1))
        x[x_idx] .= BDF.factors[i] \ y[y_idx]
    end
    return x
end
function \(BDF::BlockFactors{T}, y::AbstractVector{T}) where T
    x = Array{T}(undef, BDF.n)
    x_idx, y_idx = 0:0, 0:0
    my = size(y)[1]
    for i in BDF.indices
        x_idx = x_idx.stop .+ (1:size(BDF.factors[i],2))
        y_idx = y_idx.stop .+ (1:size(BDF.factors[i],1))
        x[x_idx] .= BDF.factors[i] \ y[y_idx]
    end
    return x
end
export \

import LinearAlgebra.ldiv!
"""
    ldiv!(BDF::SparseBlockFactors, y::AbstractVecOrMat)

Backsubstitution for `SparseBlockFactors`. For square blocks only.
"""
function ldiv!(BDF::SparseBlockFactors{T}, y::AbstractVector{T}) where T
    idx = 0:0
    for i in BDF.indices
        idx = idx.stop .+ (1:BDF.factors[i].n)
        y[idx] .= ldiv!(BDF.factors[i], y[idx])
    end
    return y
end
"""
    ldiv!(BDF::BlockFactors, y::AbstractVecOrMat)

Backsubstitution for `BlockFactors`. For square blocks only.
"""
function ldiv!(BDF::BlockFactors{T}, y::AbstractVector{T}) where T
    idx = 0:0
    for i in BDF.indices
        idx = idx.stop .+ (1:size(BDF.factors[i],2))
        y[idx] .= ldiv!(BDF.factors[i], y[idx])
    end
    return y
end
"""
    ldiv!(x::AbstractVecOrMat, BDF::SparseBlockFactors, y::AbstractVecOrMat)

Backsubstitution for `SparseBlockFactors`. For square blocks only.
"""
function ldiv!(x::AbstractVecOrMat{T}, BDF::SparseBlockFactors{T}, y::AbstractVector{T}) where T
    idx = 0:0
    for i in BDF.indices
        idx = idx.stop .+ (1:BDF.factors[i].n)
        x[idx] .= ldiv!(x[idx], BDF.factors[i], y[idx])
    end
    return x
end
"""
    ldiv!(x::AbstractVecOrMat, BDF::BlockFactors, y::AbstractVecOrMat)

Backsubstitution for `BlockFactors`. For square blocks only.
"""
function ldiv!(x::AbstractVecOrMat{T}, BDF::BlockFactors{T}, y::AbstractVector{T}) where T
    idx = 0:0
    for i in BDF.indices
        idx = idx.stop .+ (1:size(BDF.factors[i],2))
        x[idx] .= ldiv!(x[idx], BDF.factors[i], y[idx])
    end
    return x
end
export ldiv!

end # module
