using Test
using SeDuMi

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
        primal, dual, info = sedumi(A, b, c, SeDuMi.Cone(0, 1, [], [], [2]),
                                    fid=0)
        @test primal ≈ [1, 1, -1, -1, 1]
        @test dual ≈ [2.0, 0.0]
        @test info["pinf"] == 0.0
        @test info["dinf"] == 0.0
        @test info["numerr"] == 0.0
        @test info["iter"] == 3.0
        @test info["feasratio"] ≈ 1.0 rtol=1e-4
    end
    @testset "Unbounded" begin
        A = -[0.0 0.0 1.0 0.0
              0.0 1.0 0.0 0.0]
        b = [1.0, 0.0]
        c = [1.0, 0.0, 0.0, 1.0]
        primal, dual, info = sedumi(A, b, c, SeDuMi.Cone(0, 0, [], [], [2]),
                                    fid=0)
        @test isempty(primal)
        @test dual == [1.0, -1.0]
        @test info["pinf"] == 1.0
    end
end
