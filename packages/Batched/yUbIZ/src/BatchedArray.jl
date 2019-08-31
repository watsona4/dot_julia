export BatchedArray, BatchedMatrix, BatchedVector, inner_size, batch_size, merged_size

import LinearAlgebra
import LinearAlgebra: BLAS

"""
    AbstractBatchedArray{T, NI, N}

Abstract type batched array. A batched array use its last `N - NI` dimension as
batch dimension, it is a batch of array with dimension `NI`.
"""
abstract type AbstractBatchedArray{T, NI, N} <: AbstractArray{T, N} end

"""
    AbstractBatchedScalar{T, N}

Batched scalars.
"""
const AbstractBatchedScalar{T, N} = AbstractBatchedArray{T, 0, N}

"""
    AbstractBatchedVector{T, N}

Batched vector.
"""
const AbstractBatchedVector{T, N} = AbstractBatchedArray{T, 1, N}

"""
    AbstractBatchedMatrix{T, N}

Batched matrix.
"""
const AbstractBatchedMatrix{T, N} = AbstractBatchedArray{T, 2, N}

"""
    inner_size(batched_array) -> Tuple

Returns a tuple of size of each inner dimension of the batched array.
"""
function inner_size end

"""
    batch_size(batched_array) -> Tuple

Returns a tuple of size of each batch dimension of the batched array.
"""
function batch_size end

"""
    merged_size(batched_array) -> Tuple

Returns the size of this batched array after merging all its batched dimension together.
"""
function merged_size end

function Base.:(*)(A::AbstractBatchedMatrix, B::AbstractBatchedMatrix)
    @assert batch_size(A) == batch_size(B) "Batch size mismatch"
    LinearAlgebra.mul!(similar(B, (size(A, 1), size(B, 2), batch_size(A)...)), A, B)
end

"""
    BatchedArray{T, NI, N, AT} <: AbstractBatchedArray{T, NI, N}

A concrete type for batched arrays. `T` is the element type, `NI` is the inner sample's
dimension, `N` is the total dimension and `AT` is the array type that actually holds the
value.
"""
struct BatchedArray{T, NI, N, AT <: AbstractArray{T, N}} <: AbstractBatchedArray{T, NI, N}
    parent::AT
end

BatchedArray(NI::Int, data::AT) where {T, N, AT <: AbstractArray{T, N}} = BatchedArray{T, NI, N, AT}(data)

Base.size(x::BatchedArray) = size(x.parent)
Base.strides(x::BatchedArray) = strides(x.parent)
Base.getindex(x::BatchedArray, I...) = getindex(x.parent, I...)
Base.setindex!(x::BatchedArray, v, I...) = setindex!(x.parent, v, I...)
Base.IndexStyle(::Type{BT}) where {T, NI, N, AT, BT <: BatchedArray{T, NI, N, AT}} = IndexStyle(AT)

Base.similar(x::BatchedArray{<:Any, NI}, T::Type, dims::Dims) where NI = BatchedArray(NI, similar(x.parent, T, dims))
Base.similar(x::BatchedArray, T::Type) = similar(x, T, size(x))
Base.similar(x::BatchedArray{T}, dims::Dims) where T = similar(x, T, dims)
Base.similar(x::BatchedArray) = similar(x, eltype(x), size(x))

inner_size(x::BatchedArray{T, NI, N}) where {T, NI, N} = Tuple(size(x, i) for i in Base.OneTo(NI))
batch_size(x::BatchedArray{T, NI, N}) where {T, NI, N} = Tuple(size(x, i) for i in (NI+1):N)
batch_size(x::BatchedArray, i::Int) = batch_size(x, i)
merged_size(x::BatchedArray) = (inner_size(x)..., prod(batch_size(x)))

merge_batch_dim(x::BatchedArray{T, NI, N}) where {T, NI, N} = merge_batch_dim(Val(N-NI), x)
merge_batch_dim(::Val{1}, x::BatchedArray) = x.parent
merge_batch_dim(::Val, x::BatchedArray) = reshape(x.parent, merged_size(x)...)

function check_batch_dim_size(x, xs::BatchedArray...)
    first_batch_size = batch_size(x)
    for other in xs
        other != first_batch_size || error("Batch size mismatch expect $(first_batch_size) got $(batch_size(other))")
    end
    true
end

const BatchedVector{T, N, AT} = BatchedArray{T, 1, N, AT}
const BatchedMatrix{T, N, AT} = BatchedArray{T, 2, N, AT}

BatchedVector(data::AbstractArray) = BatchedArray(1, data)
BatchedMatrix(data::AbstractArray) = BatchedArray(2, data)

function LinearAlgebra.tr(A::BatchedMatrix)
    out = BatchedArray(0, similar(A.parent, batch_size(A)))
    batch_out = merge_batch_dim(out)
    batched_tr!(batch_out, merge_batch_dim(A))
    out
end
