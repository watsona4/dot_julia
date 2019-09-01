module SimpleRandom
import Random.randperm 

include("RV.jl")

export random_unit_vector, random_subset

"""
`random_unit_vector(d)` returns a random `d`-dimensional unit vector.
"""
function random_unit_vector(d::Int)
  v = randn(d)
  return v / norm(v)
end

"""
`random_subset` is used to create random subsets as follows:

+ `random_subset(A)`: random subset of `A` with each element
chosen with probability 1/2.
+ `random_subset(A,k)`: random `k`-element subset of `A`.
+ `random_subset(n)`: random subset of `1:n`.
+ `random_subset(n,k)`: random `k`-element subset of `1:n`.
"""
function random_subset(A::Union{Set,BitSet})
  T = typeof(A)
  B = T()
  for a in A
    if rand() < 0.5
      push!(B,a)
    end
  end
  return B
end

random_subset(n::Int) = random_subset(Set(1:n))

function random_subset(A::Union{Set,BitSet}, k::Int)
  n = length(A)
  if k<0 || k>n
    error("k = $k is out of range")
  end
  T = typeof(A)
  B = T()
  elements = collect(A)
  p = randperm(n)
  for j=1:k
    push!(B,elements[p[j]])
  end
  return B
end

function random_subset(n::Int, k::Int)
  if n<0 || k<0 || k>n
    error("n = $n and/or k = $k invalid")
  end
  x = randperm(n)
  y = x[1:k]
  return Set(y)
end


export random_choice

"""
`random_choice(weights)` randomly chooses a value from `1` to `n`,
where `n` is the number of elements in `weights`. The probability
that `k` is chosen is proportional to `weights[k]`. The `weights`
must be nonnegative and not all zero.

`random_choice(dict)` choose a random key `k` from `dict` with weight
proportional to `dict[k]`. Thus, `dict` must be of type
`Dict{S, T<:Real}`.
"""
function random_choice(weights::Vector{T}) where {T<:Real}
  vals = cumsum(weights)
  vals /= vals[end]
  idx = rand()
  for k=1:length(vals)
    @inbounds if idx <= vals[k]
      return k
    end
  end
  error("Impropper input")
end

function random_choice(d::Dict{S,T}) where {S,T<:Real}
  ks = collect(keys(d))
  n = length(ks)
  wts = [ d[ks[j]] for j=1:n ]
  idx = random_choice(wts)
  return ks[idx]
end



import Distributions

export binom_rv, poisson_rv, exp_rv

"""
`binom_rv(n,p)` generates a random binomial random value.
`p` defaults to `0.5`.
"""
binom_rv(n::Int,p::Real=0.5) = rand(Distributions.Binomial(n,p))


"""
`poisson_rv(lambda)` generates a Poisson random value with
mean `lamba` (which defaults to `1.0`).
"""
poisson_rv(lambda::Real=1.0) = rand(Distributions.Poisson(lambda))


"""
`exp_rv(theta)` returns an exponential random value with
mean `theta` (which defaults to `1.0`).
"""
exp_rv(theta::Real=1.0) = rand(Distributions.Exponential(theta))



end  # end of module
