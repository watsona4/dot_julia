# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/AsterReader.jl/blob/master/LICENSE

using FEMBase, AsterReader, Test, LinearAlgebra, SparseArrays

include(joinpath("..", "docs", "make.jl"))

@testset "AsterReader.jl" begin
    include("test_read_aster_mesh.jl")
    include("test_read_aster_results.jl")
    include("test_read_gmsh_med.jl")
end

include(joinpath("..", "docs", "deploy.jl"))
