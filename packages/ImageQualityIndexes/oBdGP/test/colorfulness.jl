@testset "colorfulness" begin
    
    @info "test: colorfulness"

    # Test against a simple result calculated by hand
    
    x = [RGB(1,0,0), RGB(0,1,0), RGB(0,0,1)]
    @test trunc(colorfulness(x)) == 337

    # Black is not colorful
    
    x = [RGB(0,0,0), RGB(0,0,0), RGB(0,0,0)]
    @test trunc(colorfulness(x)) == 0

    # White is not colorful
    
    x = [RGB(1,1,1), RGB(1,1,1), RGB(1,1,1)]
    @test trunc(colorfulness(x)) == 0

    # A grayscale image is not colorful
    
    cameraman = testimage("cameraman")
    @test colorfulness(cameraman) == 0

    # A color image with only grays is not colorful
    
    x = convert(Array{Float64}, cameraman)
    img = RGB.(x, x, x)
    @test colorfulness(img) == 0
    
    # Lena 256 is a reduced color image and so should be less colorful
    # than the original

    imga = testimage("lena_color_256")
    imgb = testimage("lena_color_512")
    
    @test  colorfulness(imga) < colorfulness(imgb) 
   
    # Test all invocation styles are equivalent
    
    c1 = colorfulness(imga)
    c2 = hasler_and_susstrunk_m3(imga)
    c3 = colorfulness(HASLER_AND_SUSSTRUNK_M3(), imga)
    c4 = assess(HASLER_AND_SUSSTRUNK_M3(), imga)

    @test c1 == c2 == c3 == c4
    
end
