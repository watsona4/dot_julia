module CumulantsUpdates
  using Cumulants
  using SymmetricTensors
  using StatsBase
  using FileIO
  using JLD2
  using Distributed
  import Cumulants: outerprodcum
  import SymmetricTensors: pyramidindices, getblockunsafe
  import LinearAlgebra: norm

  include("updates.jl")
  include("operations.jl")

  export dataupdat, momentupdat, momentarray
  export norm, moms2cums!, cums2moms, cumulantsupdate!, DataMoments, savedm, loaddm
end
