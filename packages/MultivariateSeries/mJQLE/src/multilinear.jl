export tensor

import LinearAlgebra: norm
"""
```
tensor(A, B, C) -> Array{K,3}
```
Compute the trilinear tensor ``T=(∑_{l=1}^{length(w)} A[i,l]*B[j,l]*C[k,l])_{i,j,k}``. 
"""
function tensor(A::AbstractMatrix, B::AbstractMatrix, C::AbstractMatrix)
    d1 = size(A,1)
    d2 = size(B,1)
    d3 = size(C,1)
    r = size(A,2)
    reshape(sum(A[:,i]*reshape(B[:,i]*C[:,i]',1,d2*d3) for i in 1:r),d1,d2,d3)
end


"""
```
tensor(w, A, B, C) -> Array{K,3}
```
Compute the trilinear tensor ``T=(∑_{l=1}^{length(w)} w[l]*A[i,l]*B[j,l]*C[k,l])_{i,j,k}``. 
"""
function tensor(w::Vector, A::AbstractMatrix, B::AbstractMatrix, C::AbstractMatrix)
    d1 = size(A,1)
    d2 = size(B,1)
    d3 = size(C,1)
    r = size(A,2)
    reshape(sum(w[i]*A[:,i]*reshape(B[:,i]*C[:,i]',1,d2*d3) for i in 1:r),d1,d2,d3)
end

"""
L``^p`` norm of the coefficient of the tensor `T`. The default value of p is 2.
"""
function LinearAlgebra.norm(T::Array{C,3}, p::Int64=2) where C
    n = size(T)
    r = zero(0)
    
    for i in 1:n[1]
        for j in 1:n[2]
            for k in 1:n[3]
                r += abs(T[i,j,k])^p
            end
        end
    end
    return r^(1//p)
end

function LinearAlgebra.norm(T::Array{C,3}, Infiny::Float64) where C
    n = size(T)
    r = zero(0)
    for i in 1:n[1]
        for j in 1:n[2]
            for k in 1:n[3]
                r =max(r,abs(T[i,j,k]))
            end
        end
    end
    return r
end
