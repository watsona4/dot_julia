# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/HeatTransfer.jl/blob/master/LICENSE

using FEMBase, HeatTransfer, Test, SparseArrays, LinearAlgebra

include("../docs/make.jl")

@testset "HeatTransfer.jl" begin

    @testset "stiffness matrix and heat source boundary condition" begin
        include("test_stiffness_matrix_and_heat_source_2d.jl")
    end

    @testset "heat flux boundary condition for 2d problem" begin
        include("test_heat_flux_bc_2d.jl")
    end

    @testset "heat flux boundary condition for 3d problem" begin
        include("test_heat_flux_bc_3d.jl")
    end

    @testset "heat exchange boundary condition" begin
        include("test_heat_exchange_bc.jl")
    end

end

include("../docs/deploy.jl")
