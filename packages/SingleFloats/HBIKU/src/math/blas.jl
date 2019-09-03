using LinearAlgebra.BLAS

function BLAS.axpy!(a::Single32, X::T, Y::T) where {T<:AbstractArray}
    axpy!(reinterpret(Float64,a), X, Y)
    return reinterpret(Single32,Y)
end

