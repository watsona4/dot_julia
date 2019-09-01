# This file is a part of EncodedArrays.jl, licensed under the MIT License (MIT).

using EncodedArrays
using Test

using BitOperations


@testset "varlen_diff_codec" begin
    a = zigzagdec(UInt64(0x4c6b5f94758))
    data = [a, a + 3, a - 2]
    codec = VarlenDiffArrayCodec()

    encoded = Vector{UInt8}()
    EncodedArrays.encode_data!(encoded, codec, data)
    @test encoded == [0xd8, 0x8e, 0xe5, 0xaf, 0xeb, 0x98, 0x01, 0x06, 0x09]

    data_dec = view(similar(data), :) # Use view to test that decoder doesn't resize
    @test EncodedArrays.decode_data!(data_dec, codec, encoded) === data_dec
    @test data_dec == data

    data_dec = Vector{Int64}()
    @test EncodedArrays.decode_data!(data_dec, codec, encoded) === data_dec
    @test data_dec == data

    data_dec = Vector{Int64}(undef, 2)
    @test EncodedArrays.decode_data!(data_dec, codec, encoded) === data_dec
    @test data_dec == data

    data_dec = Vector{UInt64}()
    @test EncodedArrays.decode_data!(data_dec, codec, encoded) === data_dec
    @test data_dec == data

    b = unsigned(a)
    data = [b, b + 3, b - 2]

    encoded = Vector{UInt8}()
    EncodedArrays.encode_data!(encoded, codec, data)
    @test encoded == [0xd8, 0x8e, 0xe5, 0xaf, 0xeb, 0x98, 0x01, 0x06, 0x09]

    data_dec = view(similar(data), :) # Use view to test that decoder doesn't resize
    @test EncodedArrays.decode_data!(data_dec, codec, encoded) === data_dec
    @test data_dec == data

    data_dec = Vector{Int64}()
    @test EncodedArrays.decode_data!(data_dec, codec, encoded) === data_dec
    @test data_dec == data
end # testset
