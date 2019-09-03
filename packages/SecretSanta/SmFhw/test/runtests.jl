using SecretSanta
using Test

@testset "SecretSanta" begin
    @testset "SecretSantaModel" begin
        SecretSanta.run("../test/test.json", test = true)
        @test true
    end
end
