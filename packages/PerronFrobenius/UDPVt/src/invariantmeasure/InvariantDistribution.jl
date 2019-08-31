
abstract type AbstractInvariantDistribution end

"""
	InvariantDistribution(dist, nonzero_inds)

Invariant visitiation frequencies over a partitioned state space. Fields are
`dist` (the probability distribution) and `nonzero_inds` (the indices of `dist`
with nonzero entries).
"""
struct InvariantDistribution <: AbstractInvariantDistribution
    dist::Vector{Float64} # Distribution over the simplices
    nonzero_inds::Vector{Int} # indices of nonzero entries
end

export AbstractInvariantDistribution, InvariantDistribution
