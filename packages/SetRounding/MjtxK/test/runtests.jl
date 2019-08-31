using SetRounding
using Test


@testset "setrounding(Float64)" begin
    a = 0.1; b = 0.3

    c = setrounding(Float64, RoundDown) do
        a + b
    end

    d = setrounding(Float64, RoundUp) do
        a + b
    end

    @test c == 0.39999999999999997
    @test d == 0.4
end


@testset "setrounding(Float32)" begin
    a = Float32(0.1)
    b = Float32(0.3)

    c = setrounding(Float32, RoundDown) do
       a + b
    end

    d = setrounding(Float32, RoundUp) do
       a + b
    end

    @test c == 0.4f0
    @test d == 0.40000004f0
end
