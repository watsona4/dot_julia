@testset "Block" begin
    @testset "Header" begin
        header_raw = hex2bytes("020000208ec39428b17323fa0ddec8e887b4a7c53b8c0a0a220cfd0000000000000000005b0750fce0a889502d40508d39576821155e9c9e3f5c3157f961db38fd8b25be1e77a759e93c0118a4ffd71d")
        io = IOBuffer(header_raw)
        header = Header(io)
        @testset "Parse" begin
            @test header.version == 0x20000002
            want = hex2bytes("8ec39428b17323fa0ddec8e887b4a7c53b8c0a0a220cfd000000000000000000")
            @test header.prevhash == want
            want = hex2bytes("5b0750fce0a889502d40508d39576821155e9c9e3f5c3157f961db38fd8b25be")
            @test header.merkleroot == want
            @test header.time == 0x59a7771e
            @test header.bits == 0x18013ce9
            @test header.nonce == 0x1dd7ffa4
        end
        @testset "Serialize" begin
            @test serialize(header) == header_raw
        end
        @testset "Hash" begin
            @test hash256(header) == hex2bytes("0000000000000000007e9e4c586439b0cdbe13b1370bdd9435d76a644d047523")
        end
        @testset "BIP9" begin
            @test BitcoinPrimitives.bip9(header)
            header_raw = hex2bytes("0400000039fa821848781f027a2e6dfabbf6bda920d9ae61b63400030000000000000000ecae536a304042e3154be0e3e9a8220e5568c3433a9ab49ac4cbb74f8df8e8b0cc2acf569fb9061806652c27")
            io = IOBuffer(header_raw)
            header = Header(io)
            @test !BitcoinPrimitives.bip9(header)
        end
        @testset "BIP91" begin
            @test !BitcoinPrimitives.bip91(header)
            header_raw = hex2bytes("1200002028856ec5bca29cf76980d368b0a163a0bb81fc192951270100000000000000003288f32a2831833c31a25401c52093eb545d28157e200a64b21b3ae8f21c507401877b5935470118144dbfd1")
            io = IOBuffer(header_raw)
            header = Header(io)
            @test BitcoinPrimitives.bip91(header)
        end
        @testset "BIP141" begin
            @test BitcoinPrimitives.bip141(header)
            header_raw = hex2bytes("0000002066f09203c1cf5ef1531f24ed21b1915ae9abeb691f0d2e0100000000000000003de0976428ce56125351bae62c5b8b8c79d8297c702ea05d60feabb4ed188b59c36fa759e93c0118b74b2618")
            io = IOBuffer(header_raw)
            header = Header(io)
            @test !BitcoinPrimitives.bip141(header)
        end
        @testset "Target" begin
            @test target(header) == parse(BigInt, "13ce9000000000000000000000000000000000000000000", base=16)
            @test difficulty(header) == 888171856257
        end
        @testset "Check POW" begin
            header_raw = hex2bytes("04000000fbedbbf0cfdaf278c094f187f2eb987c86a199da22bbb20400000000000000007b7697b29129648fa08b4bcd13c9d5e60abb973a1efac9c8d573c71c807c56c3d6213557faa80518c3737ec1")
            io = IOBuffer(header_raw)
            header = Header(io)
            @test check_pow(header) == true
            header_raw = hex2bytes("04000000fbedbbf0cfdaf278c094f187f2eb987c86a199da22bbb20400000000000000007b7697b29129648fa08b4bcd13c9d5e60abb973a1efac9c8d573c71c807c56c3d6213557faa80518c3737ec0")
            io = IOBuffer(header_raw)
            header = Header(io)
            @test !check_pow(header)
        end
    end
    raw_block = hex2bytes("0100000000000000000000000000000000000000000000000000000000000000000000003ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a29ab5f49ffff001d1dac2b7c0101000000010000000000000000000000000000000000000000000000000000000000000000ffffffff4d04ffff001d0104455468652054696d65732030332f4a616e2f32303039204368616e63656c6c6f72206f6e206272696e6b206f66207365636f6e64206261696c6f757420666f722062616e6b73ffffffff0100f2052a01000000434104678afdb0fe5548271967f1a67130b7105cd6a828e03909a67962e0ea1f61deb649f6bc3f4cef38c4f35504e51ec112de5c384df7ba0b8d578a4c702b6bf11d5fac00000000")
    block = Block(IOBuffer(raw_block))
    @test block.header.version == 0x00000001
    @test block.header.prevhash == fill(0x00, 32)
    @test block.header.bits == 0x1d00ffff
    @test length(block.transactions) == 1
    @test block.transactions[1].inputs[1].prevout.index == 0xffffffff
    @test block.transactions[1].outputs[1].value == 0x000000012a05f200
end
