#=
Copyright (c) 2017 Ben J. Ward & Luis Yanes

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
=#

module TestTwiddle

using Twiddle, Test

@testset "Counting" begin

    @testset "Counting zero nibbles" begin
        @test Twiddle.count_0000_nibbles(0x0F) == 1
        @test Twiddle.count_0000_nibbles(0x0F11) == 1
        @test Twiddle.count_0000_nibbles(0x0F11F111) == 1
        @test Twiddle.count_0000_nibbles(0x0F11F111F11111F1) == 1
        @test Twiddle.count_0000_nibbles(0x0F11F111F11111F10F11F111F11111F1) == 2
    end
    @testset "Counting non-zero nibbles" begin
        @test Twiddle.count_nonzero_nibbles(0x0F) == 1
        @test Twiddle.count_nonzero_nibbles(0x0F11) == 3
        @test Twiddle.count_nonzero_nibbles(0x0F11F111) == 7
        @test Twiddle.count_nonzero_nibbles(0x0F11F111F11111F1) == 15
        @test Twiddle.count_nonzero_nibbles(0x0F11F111F11111F10F11F111F11111F1) == 30
    end
    @testset "Counting one nibbles" begin
        @test Twiddle.count_1111_nibbles(0x0F) == 1
        @test Twiddle.count_1111_nibbles(0x0F11) == 1
        @test Twiddle.count_1111_nibbles(0x0F11F111) == 2
        @test Twiddle.count_1111_nibbles(0x0F11F111F11111F1) == 4
        @test Twiddle.count_1111_nibbles(0x0F11F111F11111F10F11F111F11111F1) == 8
    end
    @testset "Counting bitpairs" begin
        @test Twiddle.count_00_bitpairs(0x0F) == 2
        @test Twiddle.count_00_bitpairs(0x185DF69C185DF69C) == 6
        @test Twiddle.count_nonzero_bitpairs(0x185DF69C185DF69C) == 26
        @test Twiddle.count_11_bitpairs(0x185DF69C185DF69C) == 8
        @test Twiddle.count_11_bitpairs(0x0F) == 2
        @test Twiddle.count_01_bitpairs(0x185DF69C185DF69C) == 12
        @test Twiddle.count_10_bitpairs(0x185DF69C185DF69C) == 6
    end
    
    
end

@testset "Enumerating nibbles" begin
    @test Twiddle.enumerate_nibbles(0x42) == 0x11
    @test Twiddle.enumerate_nibbles(0x4216) == 0x1112
    @test Twiddle.enumerate_nibbles(0x4216CEDF) == 0x11122334
    @test Twiddle.enumerate_nibbles(0x4216CEDF4216CEDF) == 0x1112233411122334
    @test Twiddle.enumerate_nibbles(0x4216CEDF4216CEDF4216CEDF4216CEDF) == 0x11122334111223341112233411122334
end

@testset "Masking nibbles" begin
    args = [(UInt8, 0x18, 0x00),
            (UInt16, 0x185D, 0x000F),
            (UInt32, 0x185DF69C, 0x000F0000),
            (UInt64, 0x185DF69C185DF69C, 0x000F0000000F0000),
            (UInt128, 0x185DF69C185DF69C185DF69C185DF69C, 0x000F0000000F0000000F0000000F0000)]
    for arg in args
        @test Twiddle.nibble_mask(Twiddle.repeatpattern(arg[1], 0xDD), arg[2]) == arg[3]
    end
end

@testset "masking bits" begin
    @test Twiddle.mask(UInt64, 12) == 0x0000000000000fff
    @test Twiddle.mask(13) == 0x0000000000001fff
    @test Twiddle.mask(UInt16, 9) == 0x01ff
end

@testset "Swapping bits" begin
    @test Twiddle.swapbits(0x98, 0, 7) == 0x19
    @test Twiddle.swapbits(0x9008, 0, 15) == 0x1009
    @test Twiddle.swapbits(0x90000008, 0, 31) == 0x10000009
    @test Twiddle.swapbits(0x9000000000000008, 0, 63) == 0x1000000000000009
end

end
