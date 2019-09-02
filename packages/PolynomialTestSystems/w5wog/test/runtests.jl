using PolynomialTestSystems
using Test

@testset "getters" begin
    F = chandra(5)
    @test length(equations(F)) == 5
    @test nvariables(F) == 5
    @test bezout_number(F) == 32
    @test multi_bezout_number(F) !== nothing
    @test mixed_volume(F) == 16

    @test nsolutions(heart()) == 4
    @test nreal_solutions(heart()) == 2
end

@testset "systems" begin
    for n=3:11
        @test chandra(n) isa TestSystem
        @test cyclic(n) isa TestSystem
        @test katsura(n) isa TestSystem
    end

    @test ipp() isa TestSystem
    @test ipp2() isa TestSystem
    @test fourbar() isa TestSystem
    @test rps10() isa TestSystem

    @test boon() isa TestSystem
    @test heart() isa TestSystem
    @test d1() isa TestSystem
    @test bacillus_subtilis() isa TestSystem
    @test griewank_osborne() isa TestSystem
    @test tritangents() isa TestSystem
    @test cyclooctane() isa TestSystem
end
