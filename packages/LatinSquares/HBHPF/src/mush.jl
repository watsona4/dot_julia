"""
`mush(A,B)` takes two matrices of the same size and creates a new
matrix whose `i,j`-entry is `(A[i,j],B[i,j])`.
"""
function mush(A::Array{T,2}, B::Array{S,2}) where {S,T}
    TS = Tuple{S,T}
    r,c = size(A)
    if size(A) != size(B)
        error("Matrices must have same shape")
    end

    C = Array{TS,2}(undef,r,c)
    for i=1:r
        for j=1:c
            C[i,j] = (A[i,j],B[i,j])
        end
    end
    return C
end
