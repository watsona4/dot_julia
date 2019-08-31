@testset "anti/diagonal attack" begin
    occ = [0,0,0,0,0,0,0,0,
           0,0,1,0,0,0,1,0,
           0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,1,0,
           0,1,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0]

    att = [0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0,
           0,0,0,1,0,1,0,0,
           0,0,0,0,0,0,0,0,
           0,0,0,1,0,1,0,0,
           0,0,1,0,0,0,0,0,
           0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0]

    edg = [0,0,0,0,0,0,0,0,
           0,0,1,0,0,0,1,0,
           0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,1,0,
           0,1,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0]
    occ_uint = Bobby.cvt_to_uint(BitArray(occ))
    ui = Bobby.INT2UINT[29]
    m, e = Bobby.cross_attack(occ_uint, ui)
    @test all(Int.(Bobby.cvt_to_bitarray(m)) .== att)
    @test all(Int.(Bobby.cvt_to_bitarray(e)) .== edg)
end

@testset "bishop fen" begin
    @test test_fen("k7/8/8/8/8/8/8/B6K w Q - 0 1", 1, [10])
    @test test_fen("k7/8/8/8/8/1p6/1P6/B6K w Q - 0 1", 1, [3])
    @test test_fen("k7/8/8/8/8/1p6/1p6/B6K w Q - 0 1", 1, [4])
    @test test_fen("k7/8/8/8/7q/7B/8/7K w Q - 0 1", 1, [3])
    @test test_fen("k7/8/8/8/8/7q/6B1/7K w Q - 0 1", 1, [2])
    @test test_fen("k7/8/8/8/8/8/8/6BK w Q - 0 1", 1, [9])
    @test test_fen("kb6/8/8/8/8/8/8/7K b Q - 0 1", 1, [9])
    @test test_fen("k7/b7/Q7/8/8/8/8/7K b Q - 0 1", 1, [1])
    @test test_fen("k1b5/8/QR6/8/8/8/8/7K b Q - 0 1", 1, [1])
    @test test_fen("k7/1b6/QR6/8/8/8/8/7K b Q - 0 1", 1, [2])
end
