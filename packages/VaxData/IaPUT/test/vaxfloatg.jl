@testset "Vax Float G" begin
    g8_vax = [  0x0000000000004010,
                0x000000000000C010,
                0x000000000000402C,
                0x000000000000C02C,
                0x2D18544421FB4029,
                0x2D18544421FBC029,
                0x691B435717B847BE,
                0x691B435717B8C7BE,
                0x8B8F428A039D3861,
                0x8B8F428A039DB861,
                0x59DD428CC0CA4013,
                0x59DD428CC0CAC013 ]

    g8_ieee = Array{Float64}([  one(Float64),
                                -one(Float64),
                                3.5,
                                -3.5,
                                Float64(pi),
                                -Float64(pi),
                                1.0e37,
                                -1.0e37,
                                9.9999999999999999999999999e-38,
                                -9.9999999999999999999999999e-38,
                                1.2345678901234500000000000000,
                                -1.2345678901234500000000000000 ])

    @testset "Conversion..." begin
        for (vax, ieee) in zip(g8_vax, g8_ieee)
            @test VaxFloatG(vax) == VaxFloatG(ieee)
            @test convert(Float64, VaxFloatG(vax)) == ieee
        end
    end

    @testset "Promotion..." begin
        for t in [subtypes(VaxInt); subtypes(VaxFloat); subtypes(Signed); Float16; Float32; Float64]
            @test isa(one(t)*VaxFloatG(1), Float64)
        end
        @test isa(one(BigFloat)*VaxFloatG(1), BigFloat)
    end

    @testset "Edge cases" begin
        # Reserved Vax floating point operand
        @test_throws InexactError convert(Float64, VaxFloatG(UInt64(0x8000)))

        # Inf and NaN should error too
        @test_throws InexactError VaxFloatG(Inf64)
        @test_throws InexactError VaxFloatG(-Inf64)
        @test_throws InexactError VaxFloatG(NaN64)

        # Both IEEE zeros should be converted to Vax true zero
        @test VaxFloatG(-0.0) === VaxFloatG(0.0) === VaxFloatG(zero(UInt64))

        # Dirty zero
        @test convert(Float64, VaxFloatG(UInt64(0x08))) === zero(Float64)

        # Numbers smaller than floatmin(VaxFloatG) should underflow
        @test VaxFloatG(prevfloat(convert(Float64, floatmin(VaxFloatG)))) === zero(VaxFloatG)
        @test VaxFloatG(convert(Float64, floatmin(VaxFloatG))) === floatmin(VaxFloatG)

        # Numbers larger than floatmax(VaxFloatG) should error
        @test_throws InexactError VaxFloatG(nextfloat(convert(Float64, floatmax(VaxFloatG))))
        @test VaxFloatG(convert(Float64, floatmax(VaxFloatG))) === floatmax(VaxFloatG)
    end
end
