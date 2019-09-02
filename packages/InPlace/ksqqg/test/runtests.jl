using Test
using InPlace

@testset "in-place operations" begin

    a = big"1"
    b = a
    c = deepcopy(a)

    @inplace a += 1
    @test a == b == 2
    @test c == 1

    @inplace a = -a
    @test a == b == -2
    @test c == 1

    @inplace a = a * -1
    @test a == b == 2
    @test c == 1

    @inplace a -= 1
    @test a == b == 1
    @test c == 1
end
