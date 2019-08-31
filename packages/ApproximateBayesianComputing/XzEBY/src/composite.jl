# Composite Multivariate distribution

## Generic Composite multivariate distribution class

module CompositeDistributions

using Compat

if VERSION >= v"0.7"
  using Statistics
  using Distributed
  import Statistics: mean, median, maximum, minimum, quantile, std, var, cov, cor
else
  using Compat.Statistics
  using Compat.Distributed
  import Base: mean, median, maximum, minimum, quantile, std, var, cov, cor
end

import Base.length, Base.show
import Distributions.params
import Distributions.mean, Distributions.mode, Distributions.var, Distributions.cov
import Distributions.entropy, Distributions.insupport
import Distributions._logpdf, Distributions._pdf!
import Distributions._rand!
#import Compat.view    # Until v0.5

export AbstractCompositeContinuousDist, ContinuousMultivariateDistribution
export GenericCompositeContinuousDist, CompositeDist
export length, params, set_params!, mean, mode, var, cov, entropy
export insupport, _logpdf, gradlogpdf, _rand!


@compat abstract type AbstractCompositeContinuousDist <: ContinuousMultivariateDistribution end
#@compat abstract type AbstractCompositeDiscreteDist <: DiscreteMultivariateDistribution  end # An idea, but not implemented yet

immutable GenericCompositeContinuousDist <: AbstractCompositeContinuousDist
    dist::Vector{ContinuousDistribution}
    indices::Vector{UnitRange{Int64}}

    function GenericCompositeContinuousDist(dist::Vector{ContinuousDistribution})
      length(dist) > 0 || error("number of distributions must be positive")
      #@compat new(dist)
      indices = Array{UnitRange{Int64}}(undef,length(dist))
      idx_start = 1; idx_stop = 0
      for i in 1:length(dist)
         idx_stop += length(dist[i])
         indices[i] = idx_start:idx_stop
         idx_start += length(dist[i])
      end
      new(dist,indices)
    end
end

#typealias CompositeDist  GenericCompositeContinuousDist
const CompositeDist = GenericCompositeContinuousDist

### Parameters
length(d::GenericCompositeContinuousDist, idx::Integer) = length(d.dist[idx])
length(d::GenericCompositeContinuousDist)  = d.indices[end].stop

params(d::GenericCompositeContinuousDist, idx::Integer) = params(d.dist[idx])
function params(d::GenericCompositeContinuousDist) 
  n = length(d)
  p = Array{Tuple}(undef,n)
  for i in 1:length(d.dist)
     p[i] = params(d,i)
  end
  return p
end

#= Seems like a good idea, but not clear how to do well
function set_params!(d::GenericCompositeContinuousDist, i::Integer, x::AbstractArray{Tuple,1} ) where T
  param = params(d.dist[i])
  @assert length(param) = length(x)
  for j in 1:length(param)
     param[j] = x[j] 
  end
  if length(param) == 1 
     d.dist[i] = typeof(d.dist[i])(param[1])
  elseif length(param) == 2
  d.dist[i] = typeof(d.dist[i])(param[1],param[2])
  elseif length(param) == 3 
  d.dist[i] = typeof(d.dist[i])(param[1],param[3])
  else
     throw("Too many parameters inside Composite Distribution.")
  end
  return d
end

function set_params!(d::GenericCompositeContinuousDist, x::DenseVector{T}) where T
end
=#

### Basic statistics

mean(d::GenericCompositeContinuousDist, idx::Integer) = mean(d.dist[idx])
function mean(d::GenericCompositeContinuousDist) 
  n = length(d)
  mu = Array{Float64}(undef,n)  
  for i in 1:length(d.dist)
     mu[d.indices[i]] = mean(d,i)
  end
  return mu
end

mode(d::GenericCompositeContinuousDist, idx::Integer) = mode(d.dist[idx])
function mode(d::GenericCompositeContinuousDist) 
  n = length(d)
  mo = Array{Float64}(undef,n)
  for i in 1:length(d.dist)
     mo[d.indices[i]] = mode(d,i)
  end
  return mo
end

var(d::GenericCompositeContinuousDist, idx::Integer) = var(d.dist[idx])
function var(d::GenericCompositeContinuousDist) 
  n = length(d)
  v = Array{Float64}(undef,n)
  for i in 1:length(d.dist)
     v[d.indices[i]] = var(d,i)
  end
  return v
end

cov(d::GenericCompositeContinuousDist, idx::Integer) = cov(d.dist[idx])
function cov(d::GenericCompositeContinuousDist) 
  n = length(d)
  covar = zeros(Float64,(n,n) )
  for i in 1:length(d.dist)
     if length(d.dist[i]) == 1
        covar[d.indices[i]] = var(d,i)
     else
        covar[d.indices[i],d.indices[i]] = cov(d,i)
     end
  end
  return covar
end

entropy(d::GenericCompositeContinuousDist, idx::Integer) = entropy(d.dist[idx])
function entropy(d::GenericCompositeContinuousDist)
  mapreduce(entropy,+,d.dist)
  #=sum = 0
  for i in 1:length(d.dist)
    sum += entropy(d,i)
  end
  return sum =#
end

### Evaluation 

function index(d::GenericCompositeContinuousDist, idx::Integer)
  # note that this function is intentionally not type stable.  
  # Needs to provide scalar index for univariate distributions or range of indices for multivariate distributions
  #if d.indices[idx].start == d.indices[idx].stop
  if isa(d.dist[idx], UnivariateDistribution)
     return d.indices[idx].start
  else
     return d.indices[idx]
  end
end

function insupport(d::GenericCompositeContinuousDist, x::AbstractVector{T})  where T<:Real
  if ! (length(d) == length(x)) return false end
  for i in 1:length(d.dist)
    if !insupport(d.dist[i],x[index(d,i)]) return false end
  end
  return true
end

function _logpdf(d::GenericCompositeContinuousDist, x::AbstractArray{T,1}) where T<:Real
  sum = zero(T) 
  for i in 1:length(d.dist)
    #sum += _logpdf(d.dist[i],x[index(d,i)])
    sum += logpdf(d.dist[i],x[index(d,i)])
  end
  return sum      
end

function gradlogpdf(d::GenericCompositeContinuousDist, x::DenseVector{T}) where T<:Real
    z = Array{T}(undef,length(d))
    for i = 1:length(d.dist)
        z[index(d,i)] = gradlogpdf(d.dist[i],view(x,index(d,i)))
    end
    return z
end

### Sampling

function _rand!(d::GenericCompositeContinuousDist, x::DenseVector{T}) where T<:Real
    for i = 1:length(d.dist)
        _rand!(d.dist[i],view(x,index(d,i)))
    end
    return x
end

function _rand!(d::GenericCompositeContinuousDist, x::DenseMatrix{T}) where T<:Real
    for i = 1:length(d.dist)
        _rand!(d.dist[i],view(x,index(d,i),:))   # Check got dimensions right
    end
    return x
end

### Show

distrname(d::GenericCompositeContinuousDist) = "GenericCompositeContinuous"
function Base.show(io::IO, d::GenericCompositeContinuousDist) 
  print(io,distrname(d) * ":\n")
  for i in 1:length(d.dist)
     show(io, d.dist[i] )
     print(io,"\n")
  end
end

end # module
