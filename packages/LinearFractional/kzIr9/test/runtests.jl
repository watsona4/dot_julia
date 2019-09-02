using Test
using LinearFractional
using LinearAlgebra
using Clp
using JuMP

mytests = ["simpletest.jl", "arrayvars.jl", "transforms.jl"]

for mytest in mytests
    include(mytest)
end
