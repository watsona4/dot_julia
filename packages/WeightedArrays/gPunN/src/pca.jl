export wPCA, sPCA, rPCA, wpca, spca, rpca

using MultivariateStats: preprocess_mean, pcacov, PCA, fit, transform
using StatsBase: AnalyticWeights
using Statistics: covm

"""
    f = wPCA(x::Weighted, d=2)
    f(x)::Weighted
Works out the `MultivariateStats.PCA` to project `x` into `d` dimensions.
To ignore weights, use `wPCA(array(x), d)` instead.
Returned object can be used as a function `f(y) ≈ transform(f,array(y))`, preserving `weights(y)`.

    sPCA(x, d=2)
    rPCA(y)
Version with `s` saves the function above to a global variable, and also applies it, returning `f(x)`.
Then you can recall it, and apply it to some other data, with `rPCA(y)`.
For example:
```
julia> xx = wrandn(7,50); yy = xx[:, 1:10] |> normalise
julia> plot(xx, sPCA); plot!(yy, rPCA)
```
Now equivalent to using PCA-plot function: `pplot(xx); pplot!(yy)`. 
"""
function wPCA(x::Union{Matrix, Weighted}, outdim::Int=2) ## from  fit{T<:AbstractFloat}(::Type{PCA}, X::DenseMatrix{T};
    d, n = size(x)
    mv = preprocess_mean(array(x), nothing)
    aw = AnalyticWeights(weights(x))
    C = covm(array(x), isempty(mv) ? 0 : mv, aw, 2; corrected=true) ## corrected=true from depwarn?
    M = pcacov(C, mv; maxoutdim=outdim, pratio=0.999)
end

(pca::PCA)(x::Weighted) = Weighted(transform(pca, array(x)), weights(x), unclamp(addname(x.opt, "-PC")) )

@doc @doc(wPCA)
function sPCA(x::Union{Matrix, Weighted}, outdim::Int=2)
    global SAVED_PCA = wPCA(x, outdim)
    return rPCA(x)
end

SAVED_PCA = identity ## initially ::Function, later ::MultivariateStats.PCA

@doc @doc(wPCA)
rPCA(x...) = SAVED_PCA(x...) ## rPCA is always of type Function

## lower-case versions:
const wpca = wPCA
const spca = sPCA
const rpca = rPCA
