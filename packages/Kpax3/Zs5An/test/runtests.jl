# This file is part of Kpax3. License is MIT.

# install Plots here because travis does not find it otherwise
import Pkg
if !in("Plots", keys(Pkg.installed()))
  Pkg.add("Plots")
end

# Tell Plots/GR that we are in a headless environment
ENV["GKSwstype"] = "100"
ENV["PLOTS_TEST"] = "true"

using Distances
using Plots
using Printf
using Random
using SpecialFunctions
using Statistics
using StatsBase
using Test

gr(size=(800, 600))

cd(dirname(@__FILE__))

import Kpax3

ε = 1.0e-13
Random.seed!(1427371200)

function runtests()
  # this module is used by "model/partition_rows" tests
  include("data/partitions.jl")

  tests = [
    "data_processing/fasta_data_processing";
    "data_processing/csv_data_processing";
    "distances/simovici_jaroszewicz";
    "distances/jaccard";
    "misc/basic_functions";
    "misc/partition_functions";
    "types/settings";
    "types/data";
    "types/prior_col";
    "types/prior_row";
    "types/state";
    "types/state_list";
    "types/support";
    "model/likelihoods";
    "model/partition_cols";
    "model/partition_rows";
    "model/loss_binder"
    "optimizer/local_mode";
    "optimizer/selection";
    "optimizer/crossover";
    "optimizer/mutation";
    "mcmc/partition_ratios";
    "mcmc/log_likelihoods";
    "mcmc/weight";
    "mcmc/merge";
    "mcmc/split";
    "mcmc/gibbs";
    "mcmc/biased_random_walk";
    "mcmc/posterior";
    "mcmc/diagnostics";
    "estimate/write";
    "plots/plots"
  ]

  for t in tests
    f = string(t, ".jl")
    @printf("Going through tests in '%s'... ", f)
    include(f)
    @printf("PASSED!\n")
  end

  nothing
end

runtests()
