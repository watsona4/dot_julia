@testset "Bloom Filter" begin
    @testset "Add" begin
        bf = BloomFilter(10, 5, 99)
        item = UInt8.(collect("Hello World"))
        Bitcoin.add!(bf, item)
        expected = "0000000a080000000140"
        @test bytes2hex(Bitcoin.filter_bytes(bf)) == expected
        item = UInt8.(collect("Goodbye!"))
        Bitcoin.add!(bf, item)
        expected = "4000600a080000010940"
        @test bytes2hex(Bitcoin.filter_bytes(bf)) == expected
    end
    @testset "Load" begin
        bf = BloomFilter(10, 5, 99)
        item = UInt8.(collect("Hello World"))
        Bitcoin.add!(bf, item)
        item = UInt8.(collect("Goodbye!"))
        Bitcoin.add!(bf, item)
        expected = "0a4000600a080000010940050000006300000001"
        @test bytes2hex(Bitcoin.serialize(Bitcoin.FilterLoadMessage(bf))) == expected
    end
end
