@testset "rank/file attack" begin
    occ = [0,1,0,0,0,0,0,0,
           0,0,0,0,0,1,0,0,
           0,1,0,0,0,1,0,0,
           0,0,0,1,0,0,0,0,
           0,0,0,0,1,0,0,0,
           0,0,0,1,0,0,0,0,
           0,0,0,0,0,1,0,0,
           0,1,0,0,0,0,1,0]

    att = [0,0,1,0,0,0,0,0,
           0,0,1,0,0,0,0,0,
           0,0,1,0,0,0,0,0,
           0,0,1,0,0,0,0,0,
           1,1,0,1,0,0,0,0,
           0,0,1,0,0,0,0,0,
           0,0,1,0,0,0,0,0,
           0,0,1,0,0,0,0,0]

    edg = [0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0,
           0,0,0,0,1,0,0,0,
           0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0]
    occ_uint = Bobby.cvt_to_uint(BitArray(occ))
    ui = Bobby.INT2UINT[35]
    m, e = Bobby.orthogonal_attack(occ_uint, ui)
    @test all(Int.(Bobby.cvt_to_bitarray(m)) .== att)
    @test all(Int.(Bobby.cvt_to_bitarray(e)) .== edg)
end

@testset "rook fen" begin
    @test test_fen("k2r1r2/8/8/8/8/p3p2p/P3P2P/R3K3 w KQkq - 0 1", 1, [3])
    @test test_fen("k2r1r2/8/8/8/8/p3p2p/P3P2P/4K2R w KQkq - 0 1", 1, [2])
    @test test_fen("k2r1r2/8/8/8/8/p3p2p/P3P2P/R3K2R w KQkq - 0 1", 1, [5])
end