
export ⊙, ↓

"""
    ⊙(A,B) # \\odot
    ↓(A,B) # \\downarrow

Generalised matrix multiplication: contracts the last index of `A` with the first index of `B`. 
Either left-associative `A⊙B⊙C = (A⊙B)⊙C` like `*`, 
or right-associative `A↓B↓C = A↓(B↓C)` in fact with higher precedence, same as `^`.
"""
function ⊙(A::AbstractArray,B::AbstractArray)
    n = size(A, ndims(A))
    @assert size(B,1) == n "⊙ needs matching sizes on dimensions which touch"
    reshape(reshape(A,:,n) * reshape(B,n,:), osizes(A,B)...)
end

const ↓ = ⊙

osizes(A::AbstractArray{T,N},B::AbstractArray{S,M}) where {T,N,S,M} = 
    ntuple(i -> i<N ? size(A, i) : size(B, i-N+2), Val(N+M-2))

⊙(A::AbstractMatrix,B::AbstractMatrix) = A*B
⊙(A::AbstractMatrix,B::AbstractVector) = A*B
⊙(A::AbstractArray,B::Number) = A*B
⊙(A::Number,B::AbstractArray) = A*B
⊙(A::Number,B::Number) = A*B
