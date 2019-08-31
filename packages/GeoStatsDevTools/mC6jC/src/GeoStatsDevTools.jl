# ------------------------------------------------------------------
# Licensed under the ISC License. See LICENCE in the project root.
# ------------------------------------------------------------------

module GeoStatsDevTools

using Reexport
using Random
using StatsBase
using Distances
using LinearAlgebra
using DataFrames
using StaticArrays
using NearestNeighbors
using RecipesBase
using CSV

@reexport using Distributions

using GeoStatsBase

# implement methods for spatial objects
import GeoStatsBase: domain, npoints,
                     coordnames, coordinates!,
                     bounds, nearestlocation,
                     variables, value

# implement methods for spatial statistics
import Statistics: mean, var, quantile

# spatial domain
include("domains/point_set.jl")
include("domains/regular_grid.jl")
include("domains/structured_grid.jl")

# spatial data
include("spatialdata/geodataframe.jl")
include("spatialdata/point_set_data.jl")
include("spatialdata/regular_grid_data.jl")
include("spatialdata/structured_grid_data.jl")

# spatial partitions
include("partitions.jl")

# spatial weighting
include("weighting.jl")

# domain navigation
include("paths.jl")
include("neighborhoods.jl")

# neighborhood search
include("neighborsearch.jl")

# distances and distributions
include("distances.jl")
include("distributions.jl")

# utilities
include("utils.jl")

# solutions
include("solutions/estimation_solution.jl")
include("solutions/simulation_solution.jl")

# spatial statistics
include("statistics.jl")

# plot recipes
include("plotrecipes/domains/point_set.jl")
include("plotrecipes/domains/regular_grid.jl")
include("plotrecipes/domains/structured_grid.jl")
include("plotrecipes/domains/abstract_domain.jl")
include("plotrecipes/spatialdata.jl")
include("plotrecipes/partitions.jl")
include("plotrecipes/weighting.jl")
include("plotrecipes/solutions/estimation.jl")
include("plotrecipes/solutions/simulation.jl")

export
  # domains
  PointSet,
  RegularGrid,
  StructuredGrid,
  origin,
  spacing,

  # spatial data
  GeoDataFrame,
  PointSetData,
  RegularGridData,
  StructuredGridData,

  # partitions
  SpatialPartition,
  UniformPartitioner,
  FractionPartitioner,
  BlockPartitioner,
  BallPartitioner,
  PlanePartitioner,
  DirectionPartitioner,
  FunctionPartitioner,
  ProductPartitioner,
  HierarchicalPartitioner,
  partition,
  subsets,
  →,

  # weighting
  WeightedSpatialData,
  BlockWeighter,
  weight,

  # paths
  SimplePath,
  RandomPath,
  SourcePath,
  ShiftedPath,

  # neighborhoods
  BallNeighborhood,
  CylinderNeighborhood,
  isneighbor,

  # neighborhood search
  NearestNeighborSearcher,
  LocalNeighborSearcher,
  search!,

  # distances
  Ellipsoidal,
  evaluate,

  # distributions
  EmpiricalDistribution,
  transform!,
  quantile,
  cdf,

  # utilities
  readgeotable,

  # statistics
  mean, var,
  quantile

end
