# This file is a part of EncodedArrays.jl, licensed under the MIT License (MIT).

using EncodedArrays
using Test

using BitOperations


@testset "varlen_io" begin
    function test_encdec(T_read::Type{<:Integer}, f_read::Function, f_write::Function, x::Integer, encoded::AbstractVector{UInt8})
        buf_out = IOBuffer()
        @inferred f_write(buf_out, x)
        enc_data = take!(buf_out)
        @test enc_data == encoded

        buf_in = IOBuffer(enc_data)
        dec_x = @inferred f_read(buf_in, T_read)
        @test typeof(dec_x) == T_read
        @test dec_x == x
        @test eof(buf_in)
    end

    @testset "read_varlen, write_varlen" begin
        f_read = EncodedArrays.read_varlen
        f_write = EncodedArrays.write_varlen
        test_encdec(UInt64, f_read, f_write, UInt64(0x00), [0x00])
        test_encdec(UInt64, f_read, f_write, UInt64(0x7f), [0x7f])
        test_encdec(UInt64, f_read, f_write, UInt64(0x80), [0x80, 0x01])
        test_encdec(UInt64, f_read, f_write, UInt64(0x4c6b5f94759), [0xd9, 0x8e, 0xe5, 0xaf, 0xeb, 0x98, 0x01])
        @test_throws ErrorException test_encdec(UInt32, f_read, f_write, UInt64(0x4c6b5f94759), [0xd9, 0x8e, 0xe5, 0xaf, 0xeb, 0x98, 0x01])
    end

    @testset "read_autozz_varlen, write_autozz_varlen" begin
        f_read = EncodedArrays.read_autozz_varlen
        f_write = EncodedArrays.write_autozz_varlen
        test_encdec(UInt64, f_read, f_write, UInt64(0x4c6b5f94759), [0xd9, 0x8e, 0xe5, 0xaf, 0xeb, 0x98, 0x01])
        test_encdec(Int64, f_read, f_write, zigzagdec(UInt64(0x4c6b5f94759)), [0xd9, 0x8e, 0xe5, 0xaf, 0xeb, 0x98, 0x01])
    end
end # testset
