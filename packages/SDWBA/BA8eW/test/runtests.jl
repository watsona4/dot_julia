using SDWBA
using Test

# write your own tests here
@test 1 == 1

include("test_bent_cylinder.jl")
include("test_scatterer.jl")

println("\nPassed all tests.")
