using Test
using Cumulants
using Distributed
using SymmetricTensors
using CumulantsUpdates
using FileIO
using JLD2
using Random

import CumulantsUpdates: rep, cnorms

include("updatetest.jl")
include("operationstest.jl")
