using SparseArrays, Test
using CDCS

# Example page 4 of SeDuMi_Guide_105R5.pdf
@testset "Linear Programming example" begin
    c = [1.0, -1.0, 0.0, 0.0]
    A = [10.0 -7.0 -1.0 0.0
          1.0  0.5  0.0 1.0]
    b = [5.0, 3.0]
    sol, dual, z, status = cdcs(Matrix(A'), b, c, CDCS.Cone(0, 4), verbose=0)
    tol = 1e-2
    @test sol ≈ [47/24, 25//12, 0, 0] atol=tol rtol=tol
    @test dual ≈ [1/8, -1/4] atol=tol rtol=tol
    @test z ≈ [0, 0, 1/8, 1/4] atol=tol rtol=tol
    @test status["cost"] ≈ -1/8 atol=tol rtol=tol
end
