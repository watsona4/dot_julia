using Base58

if VERSION < v"1.0.0"
    using Base.Test
else
    using Test
end

@testset "Base58" begin

    test_data = hcat(
        [b"",                b""],
        [[0x00],             b"1"],
        [[0x00, 0x00],       b"11"],
        [b"hello world",     b"StV1DL6CwTryKyV"],
        [b"\0\0hello world", b"11StV1DL6CwTryKyV"],
        [nothing,            b"3vQOB7B6uFg4oH"],
        [b""" !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~""",
                             b"3WSNuyEGf19K7EdeCmokbtTAXJwJUdvg8QXxAacYC7kR1bQoYeWVr5iMUHvxvv4FCFY48dVUrX6BrFLod6zsEhHU9NciUXFM17h1qtveYD7ocbnXQyuY84An9nAvEjdt6H"]
    )

    # The weird eval magic gives the value of i if the test fails
    for i in 1:size(test_data, 2)
        if(test_data[1, i] != nothing)
            @eval @test Base58.base58encode($(test_data)[1, $i]) == $(test_data)[2, $i]
        end
    end

    for i in 1:size(test_data, 2)
        if(test_data[1, i] == nothing)
            @eval @test_throws ArgumentError Base58.base58decode($(test_data)[2, $i])
        else
            @eval @test Base58.base58decode($(test_data)[2, $i]) == $(test_data)[1, $i]
        end
    end

    for i in 1:size(test_data, 2)
        if(test_data[1, i] == nothing)
            @eval @test_throws ArgumentError Base58.base58decode([b"   "..., $(test_data)[2, $i]...])
        else
            @eval @test Base58.base58decode([b"    "..., $(test_data)[2, $i]...]) == $(test_data)[1, $i]
        end
    end

    @test base58decode(b"     ") == UInt8[]
    @test base58decode(b"11111") == [0x00 for i in 1:5]
end

@testset "Base58Check" begin

    # https://en.bitcoin.it/wiki/Technical_background_of_version_1_Bitcoin_addresses
    address = [0x00, 0x01, 0x09, 0x66, 0x77, 0x60, 0x06, 0x95, 0x3D, 0x55, 0x67, 0x43,
               0x9E, 0x5E, 0x39, 0xF8, 0x6A, 0x0D, 0x27, 0x3B, 0xEE]
    address_encoded = b"16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM"
    wrong_address_encoded = b"16UwLL9Risc3cfPqBUvKofHmBQ7wMtjvM"

    @test Base58.base58checkencode(address) == address_encoded
    @test Base58.base58checkdecode(address_encoded, true) == address
    @test Base58.base58checkdecode(address_encoded, false) == address
    @test_throws ArgumentError Base58.base58checkdecode(wrong_address_encoded, true)

end
