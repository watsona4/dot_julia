using RandomBooleanMatrices
using SparseArrays
using Random
using Test

Random.seed!(1337)

@testset "curveball" begin
    m = sprand(Bool, 8, 6, 0.2)
    m_old = copy(m)
    rsm = sum(m, dims = 1)
    csm = sum(m, dims = 2)
    randomize_matrix!(m, method = curveball)

    @test rsm == sum(m, dims = 1)
    @test csm == sum(m, dims = 2)
    @test m_old != m

    m2 = rand(0:1, 6, 5)
    rsm = sum(m2, dims = 1)
    csm = sum(m2, dims = 2)
    rmg = matrixrandomizer(m2, method = curveball)
    m3 = rand(rmg)

    @test rsm == sum(m3, dims = 1)
    @test csm == sum(m3, dims = 2)

    m4 = rand(rmg)

    @test m3 != m4
end
