using LinearAlgebra

import Base: iszero

pcTol(::Type{T}) where {T <: Integer}       = zero(T)
pcTol(::Type{T}) where {T <: Rational}      = zero(T)
pcTol(::Type{T}) where {T <: Float32}       = T(1f-3)
pcTol(::Type{T}) where {T <: Float64}       = T(1e-6) 

iszero(n::T, tol::T=pcTol(T)) where {T <: Number} = -tol <= n <= tol

const notvoid = Base.notnothing
const _nv = notvoid

"""
```
    parallelogram_area(m::Matrix) -> Number
```
Area of the parallelogram. The matrix is a 2x3 matrix.
"""
function parallelogram_area(m::Matrix{T}) where T <: Number
    @assert size(m) == (2, 3) "Invalid triangle."
    v1 = m[:, 2] - m[:, 3]
    v2 = m[:, 3] - m[:, 1]
    v3 = m[:, 1] - m[:, 2]
    v = max(dot(v1, v1), dot(v2, v2), dot(v3, v3))
    
    d = v3[1]*v1[2] - v1[1]*v3[2]

    v*pcTol(T)*pcTol(T) >= d*d && return zero(T)
    return d
end

