"""
   samplepoisson(λ::Function, λmax, t_, T, args...)

Sample a non homogeneous Poisson process on [t,T] via thinning.
λ is the intensity;
λmax is an upper bound for λ(x), when x in [t,T].
args contains additional arguments passed to the function λ
"""
function samplepoisson(λ::Function, λmax, t_, T, args...)
    t = t_
    tt = zeros(0)
    while t <= T
        t = t - log(rand())/λmax
        if rand() ≤ λ(t, args...)/λmax
            push!(tt, t)
        end
    end
    tt
end



"""
    counts(xx, grid)

Count how many points fall between the grid points in `grid`.

# Example:

```
  julia> counts(rand(10), 0:0.5:1)
  2-element Array{Int64,1}:
 6
 4
```
"""
function counts(xx, grid)
    c = zeros(Int, length(grid) + 1)
    for x in xx
        c[first(searchsorted(grid, x))] += 1
    end
    c[2:length(grid)]
end


function counts_sorted(xx, grid)
    n = length(grid)
    c = zeros(Int, n + 1)
    i = 1
    for x in xx
        while i <= n && x > grid[i]
            i += 1
        end
        c[i] += 1
    end
    c[2:length(grid)]
 end

################# functions for updating

"""
    updateψ!

Sample from the distribution of ψ, conditional on ζ, αψ and αζ.

Arguments:
- H::Array{Int64}      (count of events over bins)
- Δ::AbstractArray    (lengths of bins)
- n::Integer             (sample size)
- ζ::AbstractArray
- αψ
- αζ
- α1          (shape parameter of Gamma prior on ψ[1])
- β1          (rate parameter of Gamma prior on ψ[1])
"""
function updateψ!(ψ, H::Array{Int64}, Δ::AbstractArray, n::Integer, ζ::AbstractArray,
    αψ, αζ, α1, β1
)
    N = length(H)
    ψ[1] = rand(Gamma(α1 + αζ + H[1], 1.0/(β1 + αζ/ζ[1] + n*Δ[1])))
    for k in 2:(N-1)
        ψ[k] = rand(Gamma(αψ + αζ + H[k], 1.0/(αψ/ζ[k-1] + αζ/ζ[k] + n*Δ[k])))
    end
    ψ[N] = rand(Gamma(αψ + H[N], 1.0/(αψ/ζ[N-1] + n*Δ[N])))
    ψ
end

"""
    updateζ!

Sample from the distribution of ζ, conditional on ψ, αψ and αζ.

Arguments:
- ψ::AbstractArray
- αψ
- αζ
"""
function updateζ!(ζ, ψ::AbstractArray, αψ, αζ)
    N = length(ψ)
    for k in 2:N
        ζ[k-1] = rand(InverseGamma(αψ + αζ, αζ*ψ[k-1] + αψ*ψ[k]))
    end
    ζ
end


"""
    sumψζ

Helper function for updating α

Computes
```math
\\sum_{k=2}^N \\log \\frac{ψ_{k-1}ψ_k)}{ζ_k^2} -\\frac{ψ_{k-1}ψ_k}{ζ_k}
```

Arguments:
- ψ::AbstractArray
- ζ::AbstractArray
"""
function sumψζ(ψ::AbstractArray, ζ::AbstractArray)
    res = 0.0
    for k in 2:length(ψ)
        res += log(ψ[k-1]) + log(ψ[k]) - 2*log(ζ[k-1]) - (ψ[k-1] + ψ[k])/ζ[k-1]
    end
    res
end

function log_q(α, N::Integer, sumval)
    2*(N - 1)*(α*log(α) - lgamma(α)) + α*sumval
end

function log_qtilde(lα, N::Integer, sumval, Π)
    log_q(exp(lα), N, sumval) + lα + logpdf(Π, exp(lα))
end

# given ψ and ζ, draw α using symmetric random walk on log(α)
function updateα(α, ψ::AbstractArray, ζ::AbstractArray, τ, Π)
    sumval = sumψζ(ψ, ζ)
    N = length(ψ)
    lα = log(α)
    ll = log_qtilde(lα, N, sumval, Π)
    lα_prop = lα + τ * randn()
    ll_prop = log_qtilde(lα_prop, N, sumval, Π)
    if log(rand()) < (ll_prop - ll)
        return exp(lα_prop), true
    else
        return α, false
    end
end

# compute marginal likelihood for N=2..Nmax, here Nmax should be >=2
function marginal_loglikelihood(Nmax::Integer, observations::AbstractVector,
                       T0, T, n::Integer, αind, βind)
    mll = zeros(Nmax-1)
    for N in 2:Nmax
        breaks = range(T0, stop=T, length=N+1)
        Δ = diff(breaks)
        H = counts(observations, breaks)
        ltip = lgamma.(αind .+ H) .- (αind .+ H) .* log.(n*Δ .+ βind) # ltip = log terms in product
        mll[N-1] = (T-T0)*n + αind*N*log(βind) - N*lgamma(αind) + sum(ltip)
    end
    2:Nmax, mll
end

function elpd_DIC(Nmax::Integer, observations::AbstractVector,
        T0, T, n::Integer, αind, βind)
    elpd = Vector{Float64}(Nmax-1)
    for N in 2:Nmax
        breaks = range(T0, stop=T, length=N+1)
        Δ = diff(breaks)
        H = counts(observations, breaks)
        tip = (αind + H)./(n*Δ + βind)  # tip = terms in product
        ll = sum(H.*log.(tip) - n*Δ .* tip)
        νDIC = 2 * sum(H.*(log.(αind + H) - digamma.(αind + H)) )
        elpd[N-1] = ll - νDIC
    end
    2:Nmax, elpd
end

# Determine N as the largest N for which each bin has at least Nmin observations
function determine_number_breaks(Nmin::Integer, T0, T, observations::AbstractVector)
    too_many = true
    N = 1
    while too_many
        breaks = range(T0, stop=T, length=N+1) # determine breaks points with N bins
        H = counts(observations, breaks)  # compute counts over bins
        if minimum(H) >= Nmin
            N += 1 # we may be able to use more bins
        else
            too_many = false # each bin contains at least Nmin observations
            return N - 1
        end
    end
end

"""
    ebβ

Determine β by maximising the marginal likelihood, for fixed α and N.
"""
function ebβ(α, H, Δ, n, N)
    GG(α, H, Δ, n, N) = (lβ) -> -α*N*lβ[1] + N * lgamma(α) -  sum(lgamma.(α+H)) + sum((α+H).* log.(n*Δ+exp(lβ[1])))
    result = optimize(GG(α, H, Δ, n, N), [0.0], BFGS())
    exp.(result.minimizer)[1]
end

"""
    ebα

Determine α by maximising the marginal likelihood, for fixed β and N.
"""
function ebα(β, H, Δ, n, N)
    GG(β, H, Δ, n, N) = (lα) -> -exp(lα[1])*N* log(β) + N * lgamma(exp(lα[1])) -  sum(lgamma.(exp(lα[1])+H)) + sum((exp(lα[1])+H).* log.(n*Δ+β))
    result = optimize(GG(β, H, Δ, n, N), [0.0], BFGS())
    exp.(result.minimizer)[1]
end
