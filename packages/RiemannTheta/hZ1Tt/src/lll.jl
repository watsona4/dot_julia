################################################################################
#
# The LLL-Reduction Algorithm
#
# Implementration of algorithm described in :
#  Lenstra, A.K., Lenstra, H.W. & Lovász, L. Math. Ann. (1982)
#            261: 515. https://doi.org/10.1007/BF01457454
#
################################################################################

"""
  lll(b₀::AbstractMatrix{Float64})::AbstractMatrix{Float64}

Performs Lenstra-Lenstra-Lovasv reduction on the n vectors in b₀.

Parameters
----------
- b₀ : vector of n vectors of n Float64

Returns
-------
- The LLL reduction of the vectors in `b₀`
"""
function lll(b₀::Vector{Vector{Float64}})::Vector{Vector{Float64}}
    b = deepcopy(b₀) # preserve argument by working on a copy
    n = length(b)

    # initialize mu and B with zeros
    μ = zeros(n,n)
    B = zeros(n)

    # function (*) of page 521
    function ☼(l)
        abs(μ[k,l]) < 0.5 && return
        r = round(μ[k,l])
        b[k] .-= r * b[l]
        μ[k,1:l-1] .-= r * μ[l,1:l-1]
        μ[k,l] -= r
    end

    b₂ = similar(b)
    for t in 1:n
        b₂[t] = copy(b[t])
        for j in 1:t-1
            μ[t,j] = dot(b[t], b₂[j]) / B[j]
            b₂[t] .-= μ[t,j] * b₂[j]
        end
        B[t] = dot(b₂[t], b₂[t])
    end

    k = 2
    while k <= n
        ☼(k-1)
        if B[k] >= (0.75 - μ[k,k-1]^2) * B[k-1]
            foreach(☼, k-2:-1:1)
            k += 1
        else
            μₒ = μ[k,k-1]
            Bₒ = B[k] + μₒ^2 * B[k-1]
            μ[k,k-1] = μₒ * B[k-1] / Bₒ
            B[k] = B[k] * B[k-1] / Bₒ
            B[k-1] = Bₒ

            bₒ = b[k] ; b[k] = b[k-1] ; b[k-1] = bₒ
            for j in 1:k-2
                tmp = μ[k,j] ; μ[k,j] = μ[k-1,j] ; μ[k-1,j] = tmp
            end
            for t in k+1:n
                tmp = μ[k,k-1] - μₒ * μ[t,k]
                μ[t,k-1] = μ[t,k] + μ[k,k-1] * tmp
                μ[t,k]   = tmp
            end

            k = max(2, k-1)
        end
    end
    b
end
