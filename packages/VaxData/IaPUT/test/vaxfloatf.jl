@testset "Vax Float F" begin
    f4_vax = [  0x00004080,
                0x0000C080,
                0x00004160,
                0x0000C160,
                0x0FD04149,
                0x0FD0C149,
                0xBDC27DF0,
                0xBDC2FDF0,
                0x1CEA0308,
                0x1CEA8308,
                0x0652409E,
                0x0652C09E ]

    f4_ieee = Array{Float32}([  1.000000,
                               -1.000000,
                                3.500000,
                               -3.500000,
                                3.141590,
                               -3.141590,
                                9.9999999E+36,
                               -9.9999999E+36,
                                9.9999999E-38,
                               -9.9999999E-38,
                                1.23456789,
                               -1.23456789 ])

    @testset "Conversion..." begin
        for (vax, ieee) in zip(f4_vax, f4_ieee)
            @test VaxFloatF(vax) == VaxFloatF(ieee)
            @test convert(Float32, VaxFloatF(vax)) == ieee
        end
    end

    @testset "Promotion..." begin
        for t in [subtypes(VaxInt); Int8; Int16; Int32; Float16; Float32; VaxFloatF]
            @test isa(one(t)*VaxFloatF(1), Float32)
        end

        for t in [Int64, Int128, BigInt, Float64]
            @test isa(one(t)*VaxFloatF(1), Float64)
        end
        @test isa(one(BigFloat)*VaxFloatF(1), BigFloat)
    end

    @testset "Edge cases" begin
        # Reserved Vax floating point operand
        @test_throws InexactError convert(Float32, VaxFloatF(UInt32(0x8000)))

        # Inf and NaN should error too
        @test_throws InexactError VaxFloatF(Inf32)
        @test_throws InexactError VaxFloatF(-Inf32)
        @test_throws InexactError VaxFloatF(NaN32)

        # Both IEEE zeros should be converted to Vax true zero
        @test VaxFloatF(-0.0f0) === VaxFloatF(0.0f0) === zero(VaxFloatF)

        # Dirty zero
        @test convert(Float32, VaxFloatF(UInt32(0x40))) === zero(Float32)

        # Numbers smaller than floatmin(VaxFloatF) should underflow
        @test VaxFloatF(prevfloat(convert(Float32, floatmin(VaxFloatF)))) === zero(VaxFloatF)
        @test VaxFloatF(convert(Float32, floatmin(VaxFloatF))) === floatmin(VaxFloatF)

        # Numbers larger than floatmax(VaxFloatF) should error
        @test_throws InexactError VaxFloatF(nextfloat(convert(Float32, floatmax(VaxFloatF))))
        @test VaxFloatF(convert(Float32, floatmax(VaxFloatF))) === floatmax(VaxFloatF)
    end
end
