__precompile__()

module GeostatInversion

import IterativeSolvers
import Random
import RobustPmap
import Distributed
using LinearAlgebra

include("FFTRF.jl")
include("RandMatFact.jl")
include("FDDerivatives.jl")

include("direct.jl")
include("lowrank.jl")
include("lsqr.jl")
#include("lm.jl")

function randsvdwithseed(Q, numxis, p, q, seed::Nothing)
	return RandMatFact.randsvd(Q, numxis, p, q)
end

function randsvdwithseed(Q, numxis, p, q, seed::Int)
	Random.seed!(seed)
	return RandMatFact.randsvd(Q, numxis, p, q)
end

function getxis(::Type{Val{:iwantfields}}, samplefield::Function, numfields::Int, numxis::Int, p::Int, q::Int=3, seed=nothing)
	fields = RobustPmap.rpmap(i->samplefield(), 1:numfields; t=Array{Float64, 1})
	lrcm = LowRankCovMatrix(fields)
	Z = randsvdwithseed(lrcm, numxis, p, q, seed)
	xis = Array{Array{Float64, 1}}(undef, numxis)
	for i = 1:numxis
		xis[i] = Z[:, i]
	end
	return xis, fields
end

"""
Get the parameter subspace that will be explored during the inverse analysis

```
getxis(samplefield::Function, numfields::Int, numxis::Int, p::Int, q::Int=3, seed=nothing)
getxis(Q::Matrix, numxis::Int, p::Int, q::Int=3, seed=nothing)
```

Arguments:

- samplefield : a function that takes no arguments and returns a sample of the field
- Q : the covariance matrix of the parameter field
- numfields : the number of fields that will be used to find the subspace
- numxis : the dimension of the subspace
- p : oversampling parameter when estimating the range of the covariance matrix (see Halko et al, SIAM Rev., 2011)
- q : number of power iterations when estimating the range of the covariance matrix (see Halko et al, SIAM Rev., 2011)
- seed : an optional seed to use when doing the randomized matrix factorization
"""
function getxis(samplefield::Function, numfields::Int, numxis::Int, p::Int, q::Int=3, seed=nothing)
	xis, _ = getxis(Val{:iwantfields}, samplefield, numfields, numxis, p, q, seed)
	return xis
end

function getxis(Q::Matrix, numxis::Int, p::Int, q::Int=3, seed=nothing)#numxis is the number of xis, p is oversampling for randsvd accuracy, q is the number of power iterations -- see review paper by Halko et al
	xis = Array{Array{Float64, 1}}(undef, numxis)
	Z = randsvdwithseed(Q, numxis, p, q, seed)
	for i = 1:numxis
		xis[i] = Z[:, i]
	end
	return xis
end

function srga(forwardmodel::Function, s0::Vector, X::Vector, xis::Array{Array{Float64, 1}, 1}, R, y::Vector, Kred; maxiters::Int=5, delta::Float64=sqrt(eps(Float64)), xtol::Float64=1e-6, pcgafunc=pcgadirect, callback=(s, obs_cal)->nothing)
	S = sprandn(Kred, length(y), ceil(Int, log(length(y))) / Kred)
	scale!(S, 1 / sqrt(length(y)))
	return pcgafunc(x->S * forwardmodel(x), s0, X, xis, S * R * S', S * y; maxiters=maxiters, delta=delta, xtol=xtol, callback=callback)
end

"""
Randomized (principal component) geostatistical approach

Example:

```
function rga(forwardmodel::Function, s0::Vector, X::Vector, xis::Array{Array{Float64, 1}, 1}, R, y::Vector, S; maxiters::Int=5, delta::Float64=sqrt(eps(Float64)), xtol::Float64=1e-6, pcgafunc=pcgadirect, callback=(s, obs_cal)->nothing)
```

Arguments:

- forwardmodel : param to obs map h(s)
- s0 : initial guess
- X : mean of parameter prior (replace with B*X drift matrix later for p>1)
- xis : K columns of Z = randSVDzetas(Q,K,p,q) where Q is the parameter covariance matrix
- R : covariance of measurement error (data misfit term)
- y : data vector
- S : sketching matrix
- maxiters : maximum # of PCGA iterations
- delta : the finite difference step size
- xtol : convergence tolerance for the parameters
- callback : a function of the form `(params, observations)->...` that is called during each iteration
"""
function rga(forwardmodel::Function, s0::Vector, X::Vector, xis::Array{Array{Float64, 1}, 1}, R, y::Vector, S; maxiters::Int=5, delta::Float64=sqrt(eps(Float64)), xtol::Float64=1e-6, pcgafunc=pcgadirect, callback=(s, obs_cal)->nothing)
	return pcgafunc(x->S * forwardmodel(x), s0, X, xis, S * R * S', S * y; maxiters=maxiters, delta=delta, xtol=xtol, callback=callback)
end

pcga = pcgadirect
#TODO implement a pcga that adaptively selects between lsqr and direct based on the number of observations

end
