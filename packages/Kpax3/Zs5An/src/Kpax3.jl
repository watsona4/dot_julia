# This file is part of Kpax3. License is MIT.

module Kpax3
  #################
  # Load packages #
  #################
  import Clustering
  import DelimitedFiles
  import Distances
  import FileIO
  import KernelDensity
  import Printf
  import RecipesBase
  import SpecialFunctions
  import StatsBase

  ####################
  # Export functions #
  ####################
  export

  # types
  KSettings,
  AminoAcidData,
  CategoricalData,
  AminoAcidState,

  # distances
  distaamtn84,

  # algorithms
  kpax3mcmc,
  kpax3ga,

  # estimation
  kpax3estimate,
  optimumstate,

  # i/o
  initializepartition,
  normalizepartition,
  readfasta,
  categorical2binary,
  save,
  loadaa,
  writeresults,
  readposteriork,
  readposteriorP,
  readposteriorC,

  # diagnostics
  traceR,
  traceC,

  # plot
  plotD,
  plotk,
  plotP,
  plotC,
  plottrace,
  plotdensity,
  plotjump,
  plotdgn

  ##############
  # Load Types #
  ##############
  include("types/types.jl")

  ########################
  # Load basic functions #
  ########################
  include("misc/misc.jl")

  #################
  # Load the rest #
  #################
  include("data_processing/data_processing.jl")
  include("distances/distances.jl")
  include("model/model.jl")
  include("optimizer/optimizer.jl")
  include("mcmc/mcmc.jl")
  include("estimate/estimate.jl")
  include("plots/plots.jl")
end
