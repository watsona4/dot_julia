@testset "king" begin
    b = Bobby.set_board()
    
    kv = Bobby.gen_king_valid(Bobby.INT2UINT[61])
    @test length(kv) == 5
    kvw = [0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0,
           0,0,0,1,1,1,0,0,
           0,0,0,1,0,1,0,0]
    @test all(Int.(Bobby.cvt_to_bitarray(kv)) .== kvw)
    
    akv = Bobby.gen_all_king_valid_moves()
    @test all(Int.(Bobby.cvt_to_bitarray(akv[Bobby.INT2UINT[61]])) .== kvw)

    @test test_fen("k7/8/8/8/8/8/8/4K3 w - - 0 1", 1, [5])
    @test test_fen("k7/8/8/8/8/8/8/4K2R w - - 0 1", 1, [14])
    @test test_fen("k7/8/8/8/8/8/8/4K2R w K - 0 1", 1, [15])
    @test test_fen("1k6/8/8/8/8/8/8/R3K3 w K - 0 1", 1, [15])
    @test test_fen("1k6/8/8/8/8/8/8/R3K3 w Q - 0 1", 1, [16])
    @test test_fen("1k6/8/8/8/8/3r4/8/R3K3 w Q - 0 1", 1, [13])
    @test test_fen("1k6/8/8/8/8/2r5/8/R3K3 w Q - 0 1", 1, [15])
    @test test_fen("1k6/8/8/8/8/5r2/8/4K2R w Q - 0 1", 1, [12])
    @test test_fen("r3k3/8/8/8/8/8/8/6K1 b - - 0 1", 1, [15])
    @test test_fen("r3k3/8/8/8/8/8/8/6K1 b q - 0 1", 1, [16])
    @test test_fen("r3k3/8/8/8/8/8/8/1R4K1 b q - 0 1", 1, [16])
    @test test_fen("r3k3/8/8/8/8/8/8/2R3K1 b q - 0 1", 1, [15])
    @test test_fen("r3k3/8/8/8/8/8/8/3R2K1 b q - 0 1", 1, [13])
    @test test_fen("r3k3/8/8/8/8/8/8/4R1K1 b q - 0 1", 1, [4])
    @test test_fen("k3r3/8/8/8/8/8/8/4K2R w K - 0 1", 1, [4])
    @test test_fen("k7/8/8/8/6p1/6Pp/6PP/r6K w - - 0 1", 1, [0])
end
