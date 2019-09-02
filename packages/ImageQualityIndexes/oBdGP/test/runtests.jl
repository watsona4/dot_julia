using ImageQualityIndexes
using Test, ReferenceTests, TestImages
using Statistics

include("testutils.jl")

@testset "ImageQualityIndexes" begin

    include("psnr.jl")
    include("ssim.jl")
    include("colorfulness.jl")
    
end

nothing
