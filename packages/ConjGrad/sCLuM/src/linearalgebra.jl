
genblas_dot(x::T, y::T) where {T <: LinearAlgebra.BlasFloat} = BLAS.dot(x,y)
genblas_dot(x, y) = dot(x,y)

function genblas_dot(x, y, comm)
    @assert eltype(x) == eltype(y)
    result = zero(eltype(x))
    local_sum::eltype(x) = dot(x, y)

    if(!ismissing(comm))
        result = MPI.allreduce([local_sum], MPI.SUM, comm)[1]
    else
        result = local_sum
    end

    return result
end

genblas_scal!(a::T, x::Vector{T}) where {T <: LinearAlgebra.BlasFloat} = BLAS.scal!(length(x), a, x, 1)
genblas_scal!(a, x) = x .*= a

genblas_axpy!(a::T, x::Vector{T}, y::Vector{T}) where {T <: LinearAlgebra.BlasFloat} = BLAS.axpy!(a, x, y)
genblas_axpy!(a, x, y) = y .+= a.*x

genblas_nrm2(x::Vector{T}) where {T <: LinearAlgebra.BlasFloat} = BLAS.nrm2(length(x), x, 1)
genblas_nrm2(x) = norm(x)
