export decompose, cst_rkf, eps_rkf, weights, normlz

import LinearAlgebra: diagm

#------------------------------------------------------------------------
eps_rkf = eps::Float64 -> function (S)
  i :: Int = 1;
  while i<= length(S) && S[i]/S[1] > eps
    i+= 1;
  end
  i-1;
end

cst_rkf = r::Int64 -> function (S) return r end


# Decomposition of the pencil of matrices
function decompose(H::Vector{Matrix{C}}, rkf::Function ) where C

    U, S, V = svd(H[1])       # H0= U*diag(S)*V'
    r = rkf(S)

    Sr = S[1:r]
    Sinv = diagm(0 => [one(C)/S[i] for i in 1:r])

    M = []
    for i in 2:length(H)
    	push!(M, Sinv*conj(U[:,1:r]')*H[i]*V[:,1:r] )
    end

    n  = length(M)
    M0 = sum(M[i]*rand(Float64) for i in 1:n)

    E = eigvecs(M0)

    Xi = fill(zero(E[1,1]),n+1,r)
    for i in 1:r
        Xi[1,i]=1
    end
    for i in 1:r
    	for j in 1:n
	    Xi[j+1,i] = (E[:,i]\(M[j]*E[:,i]))[1]
	end
    end

    X = (U[:,1:r].* Sr')*E
    Y = (E \ V[:,1:r]')'

    return Xi, X, Y
end

#------------------------------------------------------------------------
"""
```
decompose(σ :: Series{C,M}, rkf :: Function)
```
Decompose the series ``σ`` as a weighted sum of exponentials.
Return ``ω``, ``Ξ`` where
 - ``ω`` is the vector of weights,
 - ``Ξ`` is the matrix of frequency points, stored per row.
The list of monomials of degree ``\\leq {d-1 \\over 2}`` are used to construct
the Hankel matrix, where ``d`` is the maximal degree of the moments in ``σ``.

The optional argument `rkf` is the rank function used to determine the numerical rank from the vector S of singular values. Its default value `eps_rkf(1.e-6)` determines the rank as the first i s.t. S[i+1]/S[i]< 1.e-6 where S is the vector of singular values.

If the rank function cst_rkf(r) is used, the SVD is truncated at rank r.
"""
function decompose(sigma::Series{R,M}, rkf::Function = eps_rkf(1.e-6)) where {R, M}
    d = maxdegree(sigma)
    X = variables(sigma)

    B0 = monoms(X, div(d-1,2))
    B1 = monoms(X, div(d-1,2))

    H = Matrix{R}[hankel(sigma, B0, B1)]
    for x in X
        push!(H, hankel(sigma, B0, [b*x for b in B1]))
    end

    Xi, X, Y = decompose(H, rkf)

    r = size(Xi,2)
    w = fill(one(eltype(Xi)),r)

    for i in 1:r
        w[i] = Xi[1,i]
        Xi[:,i]/= Xi[1,i]
        w[i]*= X[1,i]
        w[i]*= Y[1,i]
    end

    return w, Xi[2:end,:]

end

#------------------------------------------------------------------------
function normlz(M,i)
    diagm(0 => [1/M[i,j] for j in 1:size(M,1)])*M
end
