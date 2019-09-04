using Test
using Theta
using LinearAlgebra

@testset "Theta" begin
    include("theta_test.jl")
    include("lattice_test.jl")
end
