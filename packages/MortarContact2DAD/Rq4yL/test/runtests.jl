# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/MortarContact2DAD.jl/blob/master/LICENSE

using FEMBase, MortarContact2DAD, Test, LinearAlgebra, SparseArrays, Statistics,
      DelimitedFiles

include(joinpath("..", "docs", "make.jl"))

@testset "MortarContact2DAD.jl" begin
    @testset "test_01.jl" begin include("test_01.jl") end
    @testset "test_02.jl" begin include("test_02.jl") end
    @testset "test_contact_1.jl" begin include("test_contact_1.jl") end
    @testset "test_contact_2.jl" begin include("test_contact_2.jl") end
    @testset "test_contact_projection.jl" begin include("test_contact_projection.jl") end
end

include(joinpath("..", "docs", "deploy.jl"))
