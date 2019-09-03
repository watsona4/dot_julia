using StressTest
using Test, Random

@testset "dream(seconds) duration within 1% of target duration" begin
    rng = Random.seed!(1234)
    for duration in (rand(5) .* 2)
        e = @elapsed dream(duration)
        @test isapprox(e,duration,rtol=0.01)
    end
end
