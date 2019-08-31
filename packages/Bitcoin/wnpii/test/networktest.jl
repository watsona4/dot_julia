@testset "Network" begin
    @testset "Peer" begin
        @testset "IP -> Bytes" begin
            want = hex2bytes("00000000000000000000ffff0a000001")
            @test Bitcoin.ip2bytes(ip"10.0.0.1") == want
        end
        @testset "Serialize" begin
            peer = Bitcoin.Peer(1, ip"10.0.0.1", UInt16(8333))
            want = hex2bytes("010000000000000000000000000000000000ffff0a000001208d")
            @test Bitcoin.serialize(peer, true) == want
        end
    end
    @testset "Envelope" begin
        @testset "Parse" begin
            msg = hex2bytes("f9beb4d976657261636b000000000000000000005df6e0e2")
            envelope = Bitcoin.io2envelopes(msg)[1]
            @test envelope.command == "verack"
            @test envelope.payload == UInt8[]
            msg = hex2bytes("f9beb4d976657273696f6e0000000000650000005f1a69d2721101000100000000000000bc8f5e5400000000010000000000000000000000000000000000ffffc61b6409208d010000000000000000000000000000000000ffffcb0071c0208d128035cbc97953f80f2f5361746f7368693a302e392e332fcf05050001")
            envelope = Bitcoin.io2envelopes(msg)[1]
            @test envelope.command == "version"
            @test envelope.payload == msg[25:end]
        end
        @testset "Serialize" begin
            msg = hex2bytes("f9beb4d976657261636b000000000000000000005df6e0e2")
            envelope = Bitcoin.io2envelopes(msg)[1]
            @test Bitcoin.serialize(envelope) == msg
            msg = hex2bytes("f9beb4d976657273696f6e0000000000650000005f1a69d2721101000100000000000000bc8f5e5400000000010000000000000000000000000000000000ffffc61b6409208d010000000000000000000000000000000000ffffcb0071c0208d128035cbc97953f80f2f5361746f7368693a302e392e332fcf05050001")
            envelope = Bitcoin.io2envelopes(msg)[1]
            @test Bitcoin.serialize(envelope) == msg
            want = hex2bytes("f9beb4d976657261636b000000000000000000005df6e0e2")
            envelope = Bitcoin.NetworkEnvelope("verack", UInt8[])
            @test Bitcoin.serialize(envelope) == want

        end
    end
    @testset "Message" begin
        @testset "Serialize" begin
            @testset "Version" begin
                v = VersionMessage(zero(UInt64),zero(UInt64))
                @test bytes2hex(Bitcoin.serialize(v)) == "7f11010000000000000000000000000000000000000000000000000000000000000000000000ffff00000000208d000000000000000000000000000000000000ffff00000000208d0000000000000000102f626974636f696e2e6a6c3a302e312f0000000001"
            end
            @testset "GetHeaders" begin
                block_hex = "0000000000000000001237f46acddf58578a37e213d2a6edc4884a2fcad05ba3"
                gh = GetHeadersMessage(hex2bytes(block_hex))
                @test bytes2hex(Bitcoin.serialize(gh)) == "7f11010001a35bd0ca2f4a88c4eda6d213e2378a5758dfcd6af437120000000000000000000000000000000000000000000000000000000000000000000000000000000000"
            end
            @testset "GetData" begin
                hex_msg = "020300000030eb2540c41025690160a1014c577061596e32e426b712c7ca00000000000000030000001049847939585b0652fba793661c361223446b6fc41089b8be00000000000000"
                get_data = GetDataMessage()
                block1 = hex2bytes("00000000000000cac712b726e4326e596170574c01a16001692510c44025eb30")
                append!(get_data, Bitcoin.FILTERED_BLOCK_DATA_TYPE, block1)
                block2 = hex2bytes("00000000000000beb88910c46f6b442312361c6693a7fb52065b583979844910")
                append!(get_data, Bitcoin.FILTERED_BLOCK_DATA_TYPE, block2)
                @test bytes2hex(Bitcoin.serialize(get_data)) == hex_msg
            end
        end
        @testset "Parse" begin
            @testset "Headers" begin
                hex_msg = "0200000020df3b053dc46f162a9b00c7f0d5124e2676d47bbe7c5d0793a500000000000000ef445fef2ed495c275892206ca533e7411907971013ab83e3b47bd0d692d14d4dc7c835b67d8001ac157e670000000002030eb2540c41025690160a1014c577061596e32e426b712c7ca00000000000000768b89f07044e6130ead292a3f51951adbd2202df447d98789339937fd006bd44880835b67d8001ade09204600"
                s = hex2bytes(hex_msg)
                headers = Bitcoin.PARSE_PAYLOAD["headers"](s)
                @test length(headers.headers) == 2
            end
        end
        @testset "MerkleBlock" begin
            hex_msg = "0100000082bb869cf3a793432a66e826e05a6fc37469f8efb7421dc880670100000000007f16c5962e8bd963659c793ce370d95f093bc7e367117b3c30c1f8fdd0d9728776381b4d4c86041b554b852907000000043612262624047ee87660be1a707519a443b1c1ce3d248cbfc6c15870f6c5daa2019f5b01d4195ecbc9398fbf3c3b1fa9bb3183301d7a1fb3bd174fcfa40a2b6541ed70551dd7e841883ab8f0b16bf04176b7d1480e4f0af9f3d4c3595768d06820d2a7bc994987302e5b1ac80fc425fe25f8b63169ea78e68fbaaefa59379bbf011d"
            @testset "Parse" begin
                s = hex2bytes(hex_msg)
                msg = Bitcoin.PARSE_PAYLOAD["merkleblock"](s)
                @test length(msg.hashes) == 4
                @test msg.flags == [true, false, true, true, true, false, false, false]
            end
            @testset "Is Valid" begin
                s = hex2bytes(hex_msg)
                msg = Bitcoin.PARSE_PAYLOAD["merkleblock"](s)
                @test Bitcoin.is_valid(msg)
            end
        end
    end
end
