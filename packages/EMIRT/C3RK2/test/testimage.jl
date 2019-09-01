using EMIRT 
using EMIRT.Images 
using Test

@testset "test image" begin
    img = rand(UInt8, 128,128,256)

    println("test image normalization ...")
    println("serial version: ")
    @time img3 = Images.normalize2d_serial(img)
    println("parallel version: ")
    @time img2 = Images.normalize2d(img)
    @test all( img2 .== img3 )

    println("test image mask")
    @time Images.image2mask(img; threshold = UInt8(128), sizeThreshold = UInt32(400))
end # end of test set 
