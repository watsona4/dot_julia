using SparseArrays, Test
using SeDuMi

# Example page 4 of SeDuMi_Guide_105R5.pdf
@testset "Linear Programming example" begin
    c = [1.0, -1.0, 0.0, 0.0]
    A = [10.0 -7.0 -1.0 0.0
          1.0  0.5  0.0 1.0]
    b = [5.0, 3.0]
    sol, dual, status = sedumi(A, b, c, fid=0)
    @test sol ≈ sparse([1, 2], [1, 1], [47/24, 25//12], 4, 1)
    @test dual ≈ [1/8, -1/4]
    @test iszero(status["pinf"])
    @test iszero(status["dinf"])
    @test iszero(status["numerr"])
    @test status["feasratio"] == 1
    @test status["iter"] == 4
end
