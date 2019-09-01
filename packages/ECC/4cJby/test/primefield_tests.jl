@testset "Field Element Operations" begin
    @testset "Addition" begin
        a = ECC.FieldElement(2, 31)
        b = ECC.FieldElement(15, 31)
        @test a+b == ECC.FieldElement(17, 31)
        a = ECC.FieldElement(17, 31)
        b = ECC.FieldElement(21, 31)
        @test a+b == ECC.FieldElement(7, 31)
    end
    @testset "Substraction" begin
        a = ECC.FieldElement(29, 31)
        b = ECC.FieldElement(4, 31)
        @test a-b == ECC.FieldElement(25, 31)
        a = ECC.FieldElement(15, 31)
        b = ECC.FieldElement(30, 31)
        @test a-b == ECC.FieldElement(16, 31)
    end
    @testset "Multiplication" begin
        a = ECC.FieldElement(24, 31)
        b = ECC.FieldElement(19, 31)
        @test a*b == ECC.FieldElement(22, 31)
    end
    @testset "Power" begin
        a = ECC.FieldElement(17, 31)
        @test a^3 == ECC.FieldElement(15, 31)
        a = ECC.FieldElement(5, 31)
        b = ECC.FieldElement(18, 31)
        @test a^5 * b == ECC.FieldElement(16, 31)
    end
    @testset "Division" begin
        a = ECC.FieldElement(3, 31)
        b = ECC.FieldElement(24, 31)
        @test a/b == ECC.FieldElement(4, 31)
        a = ECC.FieldElement(17, 31)
        @test a^-3 == ECC.FieldElement(29, 31)
        a = ECC.FieldElement(4, 31)
        b = ECC.FieldElement(11, 31)
        @test a^-4*b == ECC.FieldElement(13, 31)
    end
end
