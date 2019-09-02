using ImageFiltering

@testset "SSIM" begin
    @info "test: SSIM"

    iqi_a = SSIM()
    iqi_b = SSIM(KernelFactors.gaussian(1.5, 11))
    iqi_c = SSIM(KernelFactors.gaussian(1.5, 11), (1.0, 1.0, 1.0))
    @test (iqi_a.kernel == iqi_b.kernel == iqi_c.kernel) &&
          (iqi_a.W == iqi_b.W == iqi_c.W)

    iqi = SSIM()
    sz_img_3 = (3, 3, 3)

    # numerical test
    img1 = testimage("cameraman")
    img2 = testimage("lena_gray_512")
    @test ssim(img1, img2) ≈ 0.3595 atol=1e-4 # MATLAB built-in ssim result
    iqi_δ = SSIM(KernelFactors.gaussian(1.5, 11), (1.0+1e-5, 1.0, 1.0))
    @test assess(iqi_δ, img1, img2) ≈ assess(SSIM(), img1, img2) atol = 1e-4


    # Gray image
    type_list = generate_test_types([Bool, Float32, N0f8], [Gray])
    A = [1.0 1.0 1.0; 1.0 1.0 1.0; 0.0 0.0 0.0]
    B = [1.0 1.0 1.0; 0.0 0.0 0.0; 1.0 1.0 1.0]
    for T in type_list
        test_ndarray(iqi, sz_img_3, T)

        a = A .|> T
        b = B .|> T

        @test ssim(a, b) == assess(SSIM(), a, b) == SSIM()(a, b)
        @test ssim(a, a) ≈ 1.0

        # FIXME: the result of Bool type is not strictly equal to others
        eltype(T) <: Bool && continue
        test_numeric(iqi, a, b, T)
        test_numeric(iqi, channelview(a), channelview(b), T)
    end
    test_cross_type(iqi, A, B, type_list)

    # RGB image
    img1 = testimage("mandril_color")
    img2 = testimage("lena_color_512")
    @test ssim(img1, img2) ≈ 0.0664 atol=1e-4 # MATLAB built-in ssim result

    type_list = generate_test_types([Float32, N0f8], [RGB])
    A = [RGB(0.0, 0.0, 0.0) RGB(0.0, 1.0, 0.0) RGB(0.0, 1.0, 1.0)
        RGB(0.0, 0.0, 1.0) RGB(1.0, 0.0, 0.0) RGB(1.0, 1.0, 0.0)
        RGB(1.0, 1.0, 1.0) RGB(1.0, 0.0, 1.0) RGB(0.0, 0.0, 0.0)]
    B = [RGB(0.0, 0.0, 0.0) RGB(0.0, 0.0, 1.0) RGB(1.0, 1.0, 1.0)
        RGB(0.0, 1.0, 0.0) RGB(1.0, 0.0, 0.0) RGB(1.0, 0.0, 1.0)
        RGB(0.0, 1.0, 1.0) RGB(1.0, 1.0, 0.0) RGB(0.0, 0.0, 0.0)]
    for T in type_list
        test_ndarray(iqi, sz_img_3, T)

        a = A .|> T
        b = B .|> T

        @test ssim(a, b) == assess(SSIM(), a, b) == SSIM()(a, b)
        @test ssim(a, b) == ssim(channelview(a), channelview(b))
        @test ssim(a, a) ≈ 1.0

        # RGB is treated as 3d gray image
        test_numeric(iqi, a, b, T)
        test_numeric(iqi, channelview(a), channelview(b), T; filename="references/SSIM_2d_RGB")
    end
    type_list = generate_test_types([Float32, N0f8], [RGB, BGR])
    test_cross_type(iqi, A, B, type_list)

    # general Color3 images
    type_list = generate_test_types([Float32], [Lab, HSV])
    A = [RGB(0.0, 0.0, 0.0) RGB(0.0, 1.0, 0.0) RGB(0.0, 1.0, 1.0)
        RGB(0.0, 0.0, 1.0) RGB(1.0, 0.0, 0.0) RGB(1.0, 1.0, 0.0)
        RGB(1.0, 1.0, 1.0) RGB(1.0, 0.0, 1.0) RGB(0.0, 0.0, 0.0)]
    B = [RGB(0.0, 0.0, 0.0) RGB(0.0, 0.0, 1.0) RGB(1.0, 1.0, 1.0)
        RGB(0.0, 1.0, 0.0) RGB(1.0, 0.0, 0.0) RGB(1.0, 0.0, 1.0)
        RGB(0.0, 1.0, 1.0) RGB(1.0, 1.0, 0.0) RGB(0.0, 0.0, 0.0)]
    for T in type_list
        a = A .|> T
        b = B .|> T

        @test_nowarn ssim(A, b), ssim(a, B)

        @test ssim(a, b) == assess(SSIM(), a, b) == SSIM()(a, b)
        @test ssim(A, A) ≈ 1.0

        # conversion to RGB first differs from no conversion
        @test ssim(a, b) ≠ ssim(channelview(a), channelview(b))
    end
    @test ssim(A, B) ≈ ssim(Lab.(A), B) atol=1e-4
end
