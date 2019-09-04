using ValueOrientedRiskManagementInsurance
using Test
using DataFrames
using Random
using LinearAlgebra
import LinearAlgebra.⋅

println("Testing S2 Life")
include("S2Life_Test.jl")
println("Testing SST Life")
include("SSTLife_Test.jl")
println("Testing S2 Non-Life")
include("S2NonLife_Test.jl")
println("Testing ECModel")
include("ECModel_Test.jl")


println("tests completed")
