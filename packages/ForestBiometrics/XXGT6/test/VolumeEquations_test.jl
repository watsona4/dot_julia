using Test
using ForestBiometrics

@testset "volume equations" begin
    @test doyle_volume(10.0,16) == 36.0
    @test scribner_volume(10.0,16) == 55.0
    @test international_volume(10.0,16) == 71.44
end
