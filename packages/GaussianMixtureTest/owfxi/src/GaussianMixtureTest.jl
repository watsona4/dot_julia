

module GaussianMixtureTest

using Distributions, StatsBase, StatsFuns, Yeppp, LinearAlgebra

#import Yeppp: add!, exp!, log!
import StatsBase: RealArray, RealVector, RealArray, IntegerArray, IntegerVector, IntegerMatrix, IntUnitRange

export gmm, gmmrepeat, asymptoticdistribution, kstest

include("estimate.jl")
include("arithmetic.jl")
include("test.jl")
end # module
