@testset "CompactSizeUInt" begin
    @testset "Read" begin
        tests = [([0x01], 1),
                 ([0xfd, 0xd0, 0x24], 9424),
                 ([0xff, 0x70, 0x9a, 0xeb, 0xb4, 0xbb, 0x7f, 0x00, 0x00], 140444170951280)]
        for t in tests
            n = Bitcoin.read(IOBuffer(t[1]))::CompactSizeUInt
            @test n.value == t[2]
        end
    end
    @testset "Serialize" begin
        want = [0xfd, 0xfe, 0x00]
        @test Bitcoin.serialize(CompactSizeUInt(254)) == want
        want = [0xfe, 0xff, 0xff, 0xff, 0xff]
        @test Bitcoin.serialize(CompactSizeUInt(0x100000000-1)) == want
        want = [0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]
        @test Bitcoin.serialize(CompactSizeUInt(0x10000000000000000-1)) == want
        @test_throws ErrorException CompactSizeUInt(0x10000000000000000)
    end
end
