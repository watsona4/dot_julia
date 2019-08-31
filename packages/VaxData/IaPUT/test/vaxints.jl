@testset "Vax Ints" begin
    i2_vax = [ 0x0001, 0xFFFF, 0x0100, 0xFF00, 0x3039, 0xCFC7 ]
    i2_ieee = Array{Int16}([ 1, -1, 256, -256, 12345, -12345 ])

    i4_vax = [  0x00000001,
                0xFFFFFFFF,
                0x00000100,
                0xFFFFFF00,
                0x00010000,
                0xFFFF0000,
                0x01000000,
                0xFF000000,
                0x075BCD15,
                0xF8A432EB ]

    i4_ieee = Array{Int32}([          1,
                                     -1,
                                    256,
                                   -256,
                                  65536,
                                 -65536,
                               16777216,
                              -16777216,
                              123456789,
                             -123456789 ])

    @testset "VaxInt16" begin
        @testset "Conversion..." begin
            for (vax, ieee) in zip(i2_vax, i2_ieee)
                @test VaxInt16(vax) == VaxInt16(ieee)
                @test convert(Int16, VaxInt16(vax)) == ieee
            end
        end

        @testset "Promotion..." begin
            @test isa(one(Int8)*VaxInt16(1), Int16)
            @test isa(VaxInt16(1)*VaxInt16(1), Int16)
            for t in [Float16, Float32, Float64, Int16, Int32, Int64, Int128]
                @test isa(one(t)*VaxInt16(1), t)
            end
        end
    end

    @testset "VaxInt32" begin
        @testset "Conversion..." begin
            for (vax, ieee) in zip(i4_vax, i4_ieee)
                @test VaxInt32(vax) == VaxInt32(ieee)
                @test convert(Int32, VaxInt32(vax)) == ieee
            end
        end

        @testset "Promotion..." begin
            for t in [subtypes(VaxInt); Int8; Int16]
                @test isa(one(t)*VaxInt32(1), Int32)
            end

            for t in [Float16, Float32, Float64, Int32, Int64, Int128]
                @test isa(one(t)*VaxInt32(1), t)
            end
        end
    end
end

