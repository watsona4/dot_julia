export BatchedUniformScaling

"""
    BatchedUniformScaling{T, N, ST <: AbstractArray{T, N}} <: AbstractBatchedArray{T, 0, N}

Scale a batch of arrays with a batch of scalars.

    BatchedUniformScaling(scalars)

The shape of batch can be multidimentional, which means member `BatchedScale.scalars`
can be a matrix or high dimentional array, the shape of this member is the shape of batch.
`dims` defines the dimmension of each sample in the batch. It can be multidimentional
as well.
"""
struct BatchedUniformScaling{T, N, ST <: AbstractArray{T, N}} <: AbstractBatchedArray{T, 0, N}
    scalars::ST
end

inner_size(x::BatchedUniformScaling) = ()
batch_size(x::BatchedUniformScaling) = size(x.scalars)
Base.size(x::BatchedUniformScaling{T, K, N}) where {T, K, N} = (inner_size(x)..., batch_size(x)...)

Base.getindex(m::BatchedUniformScaling, I...) = getindex(m.scalars, I...)

Base.IndexStyle(::Type{<:BatchedUniformScaling}) = IndexCartesian()
Base.transpose(A::BatchedUniformScaling) = A
Base.adjoint(A::BatchedUniformScaling{<:Real}) = A
Base.adjoint(A::BatchedUniformScaling{<:Complex}) = BatchedUniformScaling(adjoint(A.scalars))

merge_batch_dim(x::BatchedUniformScaling) = vec(x.scalars)
