using Test
using CDCS

# Dual:
# max x
# [1 x
#  y 1] ⪰ 0
# which is transformed by SeDuMi into
# max x
# [    1   (x+y)/2
#  (x+y)/2     1  ] ⪰ 0
# Which is unbounded with the unbounded the ray (1, -1).
@testset "Semidefinite Programming example" begin
    @testset "Bounded" begin
        # We add y ≥ 0 to make it bounded, Now the optimal solution is `(2, 0)`
        # with the matrix [1 1
        #                  1 1] of eigenvalues (0, 2).
        A = -[0.0 0.0 0.0 1.0 0.0
              1.0 0.0 1.0 0.0 0.0]
        b = [1.0, 0.0]
        c = [0.0, 1.0, 0.0, 0.0, 1.0]
        primal, dual, z, info = cdcs(Matrix(A'), b, c, CDCS.Cone(0, 1, [], [2]),
                                     verbose=0)
        @test primal ≈ [1, 1, -1, -1, 1] atol=1e-3
        @test dual ≈ [2.0, 0.0] atol=1e-3
        @test z ≈ [0, 1, 1, 1, 1] atol=1e-3
        @test info["problem"] == 0.0
    end
    @testset "Unbounded" begin
        A = -[0.0 0.0 1.0 0.0
              0.0 1.0 0.0 0.0]
        b = [1.0, 0.0]
        c = [1.0, 0.0, 0.0, 1.0]
        primal, dual, z, info = cdcs(Matrix(A'), b, c, CDCS.Cone(0, 0, [], [2]),
                                     verbose=0)
        @test primal == [Inf, -Inf, -Inf, Inf]
        @test dual == [Inf, -Inf]
        @test z == [Inf, -Inf, -Inf, Inf]
        @test info["problem"] == 1.0
    end
end
