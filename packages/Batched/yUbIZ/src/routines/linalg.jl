"""
    batched_tr!(B::AbstractVector{T}, A::AbstractArray{T, 3})

Perform batched matrix trace.
"""
function batched_tr!(B::AbstractVector{T}, A::AbstractArray{T, 3}) where T
    @assert size(A, 1) == size(A, 2) "Expect a square matrix" # checksquare
    @boundscheck size(A, 3) == size(B, 1) || error("Batch size mismatch")

    nbatch = size(A, 3)
    n = size(A, 1)
    @inbounds for k in 1:nbatch
        for i in 1:n
            B[k] += A[i, i, k]
        end
    end
    B
end
