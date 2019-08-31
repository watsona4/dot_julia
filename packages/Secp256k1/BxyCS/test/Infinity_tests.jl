@testset "Infinity Arithmetic" begin
    posinf = Secp256k1.Infinity(1)
    neginf = Secp256k1.Infinity(-1)
    @testset "Equal" begin
        @test posinf != 3
        @test posinf != -7
        @test neginf != 0
    end
    @testset "Addition" begin
        @test +posinf == posinf
        @test +neginf == neginf
        @test posinf + 3 == posinf
        @test posinf + 3 + 12 + 1 == posinf
        @test neginf + 2 == neginf
        @test neginf + 112 - 7 == neginf
    end
    @testset "Substraction" begin
        @test -posinf == neginf
        @test -neginf == posinf
        @test posinf - 3 == posinf
        @test posinf - 3 - 12 - 1 == posinf
        @test neginf - 2 == neginf
        @test neginf - 112 - 7 == neginf
    end
    @testset "Multiplication" begin
        @test 0 * posinf == 0
        @test 3 * posinf == posinf
        @test -3 * posinf == neginf
        @test 0 * neginf == 0
        @test 7 * neginf == neginf
        @test -2 * neginf == posinf
    end
    @testset "Exponentiation" begin
        @test posinf^0  == posinf
        @test neginf^0  == neginf
        @test posinf^2  == posinf
        @test neginf^5  == neginf
        @test posinf^-7 == posinf
        @test neginf^-1 == neginf
    end
end
