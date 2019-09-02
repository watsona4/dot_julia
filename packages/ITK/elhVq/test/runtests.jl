using ITK
using Test
using TestImages

@testset "Sanity Check" begin
    @test ITK.verifycxx(0) == 0
    @test ITK.verifycxx(100) == 100
end

# @testset "Registration Control Check" begin
#     testimage_path = string(joinpath(dirname(dirname(pathof(TestImages)))), "/images")
#     lighthouse_path = joinpath(testimage_path, "lighthouse.png")

#     testreg1 = ITK.registerframe(lighthouse_path, lighthouse_path, "NA", false, "Amoeba")

#     @test (testreg1[1], testreg1[2]) == (0, 0)
# end
