# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMBeam.jl/blob/master/LICENSE

using FEMBase, FEMBeam, Test, LinearAlgebra, SparseArrays

include("../docs/make.jl")

@testset "FEMBeam.jl" begin

    @testset "test beam 2d" begin
        include("test_beam2d.jl")
    end

    @testset "test beam 3D stiffness" begin
        include("test_beam3d_ex1.jl")
    end

    @testset "test beam 3D mass matrix" begin
        include("test_beam3d_mass_matrix.jl")
    end

    @testset "test supports" begin
        include("test_supports.jl")
    end

    @testset "test_rotation_matrix.jl" begin
        include("test_rotation_matrix.jl")
    end

end

include("../docs/make.jl")
