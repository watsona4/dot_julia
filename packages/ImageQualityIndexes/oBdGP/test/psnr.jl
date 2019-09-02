@testset "PSNR" begin
    @info "test: PSNR"

    iqi = PSNR()
    sz_img_3 = (3, 3, 3)

    # Gray image
    type_list = generate_test_types([Bool, Float32, N0f8], [Gray])
    A = [1.0 1.0 1.0; 1.0 1.0 1.0; 0.0 0.0 0.0]
    B = [1.0 1.0 1.0; 0.0 0.0 0.0; 1.0 1.0 1.0]
    for T in type_list
        test_ndarray(iqi, sz_img_3, T)

        a = A .|> T
        b = B .|> T

        # scalar output
        @test psnr(a, b) == assess(PSNR(), a, b)
        @test psnr(a, b) == psnr(a, b, 1.0)
        @test isinf(psnr(a, a))

        # vector output
        @test size(psnr(a, b, [1.0])) == (1,)
        @test mean(psnr(a, b, [1.0])) == psnr(a, b, 1.0)
        @test all(isinf.(psnr(a, a, [1.0])))

        # FIXME: the result of Bool type is not strictly equal to others
        eltype(T) <: Bool && continue
        test_numeric(iqi, a, b, T)
        test_numeric(iqi, channelview(a), channelview(b), T)
    end
    test_cross_type(iqi, A, B, type_list)

    # RGB image
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

        # scalar output
        @test psnr(a, b) == assess(PSNR(), a, b) == PSNR()(a, b)
        @test psnr(a, b) == psnr(a, b, 1.0) == PSNR()(a, b, 1.0)
        @test psnr(a, b) == psnr(channelview(a), channelview(b))
        @test isinf(psnr(a, a))

        # vector output
        @test_throws ArgumentError psnr(a, b, [1.0])
        @test psnr(a, b, [1.0, 1.0, 1.0]) == assess(PSNR(), a, b, [1.0, 1.0, 1.0]) == PSNR()(a, b, [1.0, 1.0, 1.0])
        @test size(psnr(a, b, [1.0, 1.0, 1.0])) == (3,)
        @test mean(psnr(a, b, [1.0, 1.0, 1.0])) != psnr(a, b) # generally they doesn't equal
        @test all(isinf.(psnr(a, a, [1.0, 1.0, 1.0])))

        test_numeric(iqi, a, b, T)
        test_numeric(iqi, channelview(a), channelview(b), T; filename="references/PSNR_2d_RGB")
    end
    type_list = generate_test_types([Float32, N0f8], [RGB, BGR])
    test_cross_type(iqi, A, B, type_list)
    @test isapprox(psnr(Lab.(A), B), psnr(A, B); rtol=1e-5)

    # general Color3 images that doesn't have peakval inferred
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

        @test psnr(a, b, [1.0, 1.0, 1.0]) == assess(PSNR(), a, b, [1.0, 1.0, 1.0]) == PSNR()(a, b, [1.0, 1.0, 1.0])
        @test all(isinf.(psnr(A, A, [1.0, 1.0, 1.0])))
    end
end
