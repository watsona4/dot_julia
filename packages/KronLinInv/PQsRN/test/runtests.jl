

using Test
using Distributed
using KronLinInv


# get all the functions
include("test_suite.jl")


nwor = nworkers()

@testset "Tests " begin
    println("\n Number of workers available: $nwor")
    println()

    printstyled("Testing 2D example \n", bold=true,color=:cyan)
    @test test2D()

    printstyled("Testing 3D example \n", bold=true,color=:cyan)
    @test test3D()

    println()
end



