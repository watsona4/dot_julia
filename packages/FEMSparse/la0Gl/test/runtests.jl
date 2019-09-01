# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMSparse.jl/blob/master/LICENSE

using Test

@testset "test FEMSparse.jl" begin
    @testset "test SparseMatrixCOO" begin
        include("test_sparsematrixcoo.jl")
    end
    @testset "test SparseMatrixCOO" begin
        include("test_sparsematrixcsc.jl")
    end
end

