using XFloats
using LinearAlgebra, SpecialFunctions
using BenchmarkTools
const BT=BenchmarkTools.DEFAULT_PARAMETERS;
BT.overhead = BenchmarkTools.estimate_overhead(); BT.evals=1; BT.time_tolerance = 2.0e-9; BT.samples = 300;

include("noelide.jl")

include("arithmetic.jl")

