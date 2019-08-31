@testset "FieldElement Operations" begin
    import Secp256k1: 𝐹, P
    @testset "Addition" begin
        @test 𝐹(2)   + 𝐹(15) == 𝐹(17)
        @test 𝐹(P-1) + 𝐹(2)  == 𝐹(1)
    end
    @testset "Substraction" begin
        @test 𝐹(29) - 𝐹(4) == 𝐹(25)
        @test 𝐹(1)  - 𝐹(2) == 𝐹(P-1)
    end
    @testset "Multiplication" begin
        a = 𝐹(2)
        b = 𝐹(P-1)
        @test a * b == 𝐹(P-2)
        @test a * 2 == 𝐹(4)
        @test 3 * b == 𝐹(P-3)
    end
    @testset "Power" begin
        @test 𝐹(2)^3 == 𝐹(8)
        @test 𝐹(P-1)^5 * 𝐹(18) == 𝐹(P-18)
    end
    @testset "Division" begin
        a = 𝐹(P-3)
        b = 𝐹(3)
        @test 𝐹(P-3) / 𝐹(3)    == 𝐹(P-1)
        @test 𝐹(1)^-rand(UInt) == 𝐹(1)
        @test 𝐹(4)^-2 == 𝐹(big"0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc3")
    end
end
