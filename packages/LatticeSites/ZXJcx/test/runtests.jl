using Test, LatticeSites, StaticArrays


@testset "site type" begin

    @test up(Bit{Float64}) == Bit(1.0)
    @test down(Bit{Float64}) == Bit(0.0)

    @test up(Spin{Float64}) == Spin(1.0)
    @test down(Spin{Float64}) == Spin(-1.0)

    @test up(Half{Float64}) == Half(0.5)
    @test down(Half{Float64}) == Half(-0.5)

end

@testset "hilbert space" begin
    for (i, each) in enumerate(HilbertSpace{Bit{Float64}}(2, 3))
        @test size(each) == (2, 3)
        @test i-1 == convert(Int, each)
    end
end

@testset "conversion" begin
    @test 1 == convert(Int,  Bit[1,      0])
    @test 1 == convert(Int, Spin[1,     -1])
    @test 1 == convert(Int, Half[0.5, -0.5])
end

@testset "rounding" begin
    @test round(Bit{Float64}, 1.2) == up(Bit{Float64})
    @test round(Bit{Float64}, 0.9) == up(Bit{Float64})
    @test round(Bit{Float64}, 0.1; threshold=0.5) == down(Bit{Float64})
    @test round(Bit{Int}, 2) == up(Bit{Int})
    @test round(Bit{Int}, 0) == down(Bit{Int})
end

@testset "static array" begin
    @test all(ups(SMatrix{2, 2, Bit{Float64}}) .== up(Bit{Float64}))
    @test all(downs(SMatrix{2, 2, Bit{Float64}}) .== down(Bit{Float64}))
end
