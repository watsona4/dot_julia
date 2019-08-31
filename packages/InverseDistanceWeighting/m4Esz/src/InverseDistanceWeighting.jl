# ------------------------------------------------------------------
# Licensed under the ISC License. See LICENCE in the project root.
# ------------------------------------------------------------------

module InverseDistanceWeighting

using GeoStatsBase
using GeoStatsDevTools

using Reexport
using NearestNeighbors
using StaticArrays
@reexport using Distances

import GeoStatsBase: solve

export InvDistWeight

"""
    InvDistWeight(var₁=>param₁, var₂=>param₂, ...)

Inverse distance weighting estimation solver.

## Parameters

* `neighbors` - Number of neighbors (default to all data locations)
* `distance`  - A distance defined in Distances.jl (default to Euclidean()
"""
@estimsolver InvDistWeight begin
  @param neighbors = nothing
  @param distance = Euclidean()
end

function solve(problem::EstimationProblem, solver::InvDistWeight)
  # retrieve problem info
  pdata = data(problem)
  pdomain = domain(problem)

  # result for each variable
  μs = []; σs = []

  for (var,V) in variables(problem)
    # get user parameters
    if var ∈ keys(solver.params)
      varparams = solver.params[var]
    else
      varparams = InvDistWeightParam()
    end

    # get valid data for variable
    X, z = valid(pdata, var)

    # number of data points for variable
    ndata = length(z)

    @assert ndata > 0 "estimation requires data"

    # allocate memory
    varμ = Vector{V}(undef, npoints(pdomain))
    varσ = Vector{V}(undef, npoints(pdomain))

    # fit search tree
    kdtree = KDTree(X, varparams.distance)

    # keep track of estimated locations
    estimated = falses(npoints(pdomain))

    # consider data locations as already estimated
    for (loc, datloc) in datamap(problem, var)
      estimated[loc] = true
      varμ[loc] = value(pdata, datloc, var)
      varσ[loc] = zero(V)
    end

    # determine number of nearest neighbors to use
    k = varparams.neighbors == nothing ? ndata : varparams.neighbors

    @assert k ≤ ndata "number of neighbors must be smaller or equal to number of data points"

    # pre-allocate memory for coordinates
    coords = MVector{ndims(pdomain),coordtype(pdomain)}(undef)

    # estimation loop
    for location in SimplePath(pdomain)
      if !estimated[location]
        coordinates!(coords, pdomain, location)

        idxs, dists = knn(kdtree, coords, k)

        weights = one(V) ./ dists
        weights /= sum(weights)

        values = view(z, idxs)

        varμ[location] = sum(weights[i]*values[i] for i in eachindex(values))
        varσ[location] = minimum(dists)
      end
    end

    push!(μs, var => varμ)
    push!(σs, var => varσ)
  end

  EstimationSolution(pdomain, Dict(μs), Dict(σs))
end

end
