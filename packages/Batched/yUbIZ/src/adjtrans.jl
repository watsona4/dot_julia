export Transpose

"""
    BatchedTranspose{T, N, S} <: AbstractBatchedMatrix{T, N}

Batched transpose. Transpose a batch of matrix.
"""
struct BatchedTranspose{T, N, S <: AbstractBatchedMatrix} <: AbstractBatchedMatrix{T, N}
    parent::S
    BatchedTranspose(X::S) where {T, N, S <: AbstractBatchedMatrix{T, N}} = new{T, N, S}(X)
end

"""
    BatchedAdjoint{T, N, S <: AbstractBatchedMatrix} <: AbstractBatchedMatrix{T, N}

Batched ajoint. Transpose a batch of matrix.
"""
struct BatchedAdjoint{T, N, S <: AbstractBatchedMatrix} <: AbstractBatchedMatrix{T, N}
    parent::S
    BatchedTranspose(X::S) where {T, N, S <: AbstractBatchedMatrix{T, N}} = new{T, N, S}(X)
end

const BatchedTransposeOrAdjoint{T, N, S} = Union{BatchedTranspose{T, N, S}, BatchedAdjoint{T, N, S}}

Base.size(m::BatchedTransposeOrAdjoint) = (size(m.parent, 2), size(m.parent, 1), size(m.parent, 3))
Base.axes(m::BatchedTransposeOrAdjoint) = (axes(m.parent, 2), axes(m.parent, 1), axes(m.parent, 3))
Base.@propagate_inbounds Base.getindex(m::BatchedTransposeOrAdjoint, i::Int, j::Int, k::Int...) = getindex(m.parent, j, i, k...)
Base.@propagate_inbounds Base.setindex!(m::BatchedTransposeOrAdjoint, v, i::Int, j::Int, k::Int...) = setindex!(m.parent, v, j, i, k...)
Base.IndexStyle(::Type{<:BatchedTransposeOrAdjoint}) = IndexCartesian()

Base.similar(A::BatchedTransposeOrAdjoint, T::Type, dims::Dims) = similar(A.parent, T, dims)
Base.similar(A::BatchedTransposeOrAdjoint, dims::Dims) = similar(A.parent, dims)
Base.similar(A::BatchedTransposeOrAdjoint, T::Type) = similar(A.parent, T)
Base.similar(A::BatchedTransposeOrAdjoint) = similar(A.parent)

Base.transpose(A::AbstractBatchedMatrix) = BatchedTranspose(A)
Base.transpose(A::BatchedTranspose) = A.parent

Base.adjoint(A::AbstractBatchedMatrix) = BatchedAdjoint(A)
Base.adjoint(A::BatchedAdjoint) = A.parent

# NOTE: this just merge the dimention of the parent
# This should never be an exported API
merge_batch_dim(A::BatchedTransposeOrAdjoint) = merge_batch_dim(A.parent)
