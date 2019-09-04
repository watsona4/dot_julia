using ULID
using Test

@testset "Pseudorandom number generation" begin
    @test isa(ULID.prng(), Float32) || isa(ULID.prng(), Float64)
    @test isfinite(ULID.prng())
    @test 0 < ULID.prng() < 1
end

@testset "Encoding based on a given system time" begin
    let t = 1469918176385
        @test ULID.encodetime(t, 10) == "01ARYZ6S41"
        @test ULID.encodetime(t, 12) == "0001ARYZ6S41"
        @test ULID.encodetime(t, 8) == "ARYZ6S41"
    end
end

@testset "Encode to a given length" begin
    @test length(ULID.encoderandom(12)) == 12
end

@testset "The reason we're here" begin
    @test length(ulid()) == 26
end
