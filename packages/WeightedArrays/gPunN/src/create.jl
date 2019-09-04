export wrand, wrandn, wrandnp, wsobol, sobol, soboln, sobolnp, wgrid, xgrid, near


##### random

"""
    wrand(d, k) = Weighted(rand(d, k))
Uniformly distributed vectors in `[0,1]^d`, as columns of a `Weighted{Matrix}`
which knows to `clamp` them to this box. Keyword `weights=true` gives weights ∝ `1 .+ rand(k)` rather than constant.
Default is now `k=1`, making a one-column matrix.

    wrandn(d, k) = π .* Weighted(randn(d, k))
Normally distributed `d`-vectors, of mean zero and std. dev. `scale=π` by default.
Keyword `max=10` clamps absolute values to be less than this. 

    wrandnp(d, k)
Absolute value of normally distributed...
"""
wrand(d::Int, k::Int=1; weights=true) = Weighted( rand(d,k), weights ? 1 .+ rand(k) : ones(k) ,0,1)

@doc @doc(wrand)
function wrandn(d::Int, k::Int=1; scale=π, weights=true, max=Inf)
    out = Weighted( scale .* randn(d,k), weights ? 1 .+ rand(k) : ones(k) )
    max==Inf ? out : clamp!(out, -max, max)
end

@doc @doc(wrand)
function wrandnp(d::Int, k::Int=1; scale=π, weights=true, max=Inf)
    out = Weighted( abs.(scale .* randn(d,k)), weights ? 1 .+ rand(k) : ones(k), 0,Inf)
    max==Inf ? out : clamp!(out, 0, max)
end

##### sub-random

import Sobol

"""    sobol(d, k)
First `k` entries from the `d`-dimensional Sobol sequence, as columns of a `Weighted{Matrix}`. """
function sobol(d::Int, k::Int=1)
    s = Sobol.SobolSeq(d)
    cols = hcat([Sobol.next!(s) for i=1:k]...)
    Weighted(cols, ones(k), 0,1)
end

using SpecialFunctions: erfinv

"""    soboln(d, k)
Normally distributed `d`-vectors, of mean zero and std. dev. π, generated from Sobol sequence,
as columns of a `Weighted{Matrix}`. """
function soboln(d::Int, k::Int=1; scale=π)
    boxed = sobol(d,k)
    Weighted( scale .* erfinv.( -1 .+ 2 .*array(boxed)), boxed.weights)
end

function sobolnp(d::Int, k::Int=1; scale=π)
    boxed = sobol(d,k)
    Weighted( scale .* erfinv.(boxed.array), boxed.weights, 0, Inf)
end


##### ordered!

wgrid(d::Int, range::AbstractRange) = Weighted(xgrid(d,range), extrema(range)...)


##### not Weighted

"""    xgrid(d, 0:0.1:5)
Gives the matrix whose colums are `d`-vectors, forming a grid of the given range in all dimensions. """
xgrid(d::Int, n::Int) = xgrid(d, 0:n)

function (xgrid(d::Int, range::AbstractRange{T}; big=false)::Matrix{T}) where T
    d==1 && return Matrix(collect(range)')

    n = length(range)
    !big && n^d > 4_000_000 && @error "xgrid is happiest with n^d = < 4×10^6, you have $n^$d... keyword big=true will disable this check"

    intcols = zeros(Int,d,n^d)
    @inbounds for i=1:n^d
        @views digits!(intcols[:,i], i-1; base=n)
    end

    range[1] .+ step(range) .* intcols
end

function near(x::Matrix, y, dist::Real; verbose=false)
    yesno = minimum( pairwise2(x,array(y)) ,dims=2) .<= (dist^2)
    sum(yesno)==0 && begin @warn("no nearby points, returning complete matrix"); return x end
    verbose && @info string("kept ",sum(yesno)," / ",size(x,2)," columns: ",round(100*sum(yesno)/size(x,2),2)," percent")
    x[:,vec(yesno)]
end

using Distances

"""
    pairwise2(x, y=x) = Distances.pairwise(SqEuclidean(), x, y)
Resulting `mat[i,j]` is distance sqared from `x[:,i]` to `y[:,j]`. Implementation varies.
"""
pairwise2(x::Matrix, y::Matrix) = pairwise(SqEuclidean(), x, y, dims=2)
pairwise2(x::Matrix) = pairwise(SqEuclidean(), x)

pairwise2(x::AbsMat, y::AbsMat) = diag(x'*x) .+ diag(y'*y)' .- 2x'*y
function pairwise2(x::AbsMat) # = diag(x'*x) .+ diag(x'*x)' .- 2x'*x
    mat = x'*x
    vec = diag(mat)
    vec .+ vec' .- 2 .* mat
end

# using Requires
#
# function init_create_req()
#     @require Distances = "???" begin
#
# 	pairwise2(x::Matrix, y::Matrix) = pairwise(SqEuclidean(), x, y)
# 	pairwise2(x::Matrix) = pairwise(SqEuclidean(), x)
#
# 	end # @require
# end
