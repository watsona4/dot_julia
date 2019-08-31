@testset "pawns" begin
    bb = Bobby.set_board()
    pl = Array{Bobby.Move,1}()
    pvl = Bobby.get_pawns_list(pl, bb)
    @test length(pvl) == 16

    pl = Array{Bobby.Move,1}()
    pvl = Bobby.get_pawns_list(pl, bb, "black")
    @test length(pvl) == 16
    
    @test test_fen("k7/8/8/8/8/1p6/P7/7K w - - 0 1", 1, [6])
    @test test_fen("k7/8/8/8/8/8/P7/7K w - - 0 1", 1, [5])
    @test test_fen("k7/8/8/8/1p6/8/P7/7K w - - 0 1", 1, [5])
    @test test_fen("k7/8/8/8/8/1p6/P7/7K b - - 0 1", 1, [5])
    @test test_fen("k7/8/8/8/Pp6/8/8/7K b - a3 0 1", 1, [5])
    @test test_fen("k7/8/8/8/P7/1p6/8/7K b - - 0 1", 1, [4])
    @test test_fen("k7/8/8/8/P7/8/1p6/7K b - - 0 1", 1, [7])
    @test test_fen("k7/8/8/8/P7/8/7p/6NK b - - 0 1", 1, [7])
    @test test_fen("k7/8/8/8/8/p7/P7/7K w - - 0 1", 1, [3])
    @test test_fen("k7/8/8/8/8/2p5/3P4/7K w - - 0 1", 1, [6])
    @test test_fen("k7/8/8/8/8/2p1p3/3P4/7K w - - 0 1", 1, [7])
    @test test_fen("k7/8/8/8/2p1p3/3P1P2/8/7K b - d3 0 1", 1, [8])
    @test test_fen("k7/3p4/8/8/8/8/8/7K b - - 0 1", 1, [5])
    @test test_fen("k7/8/8/2P5/8/8/8/7K w - - 0 1", 1, [4])
    @test test_fen("k7/8/8/2Pp4/8/8/8/7K w - - 0 1", 1, [4])
    @test test_fen("k7/8/8/2Pp4/8/8/8/7K w - d6 0 1", 1, [5])
    @test test_fen("k7/3pP3/8/8/8/8/8/7K w - - 0 1", 1, [7])
    @test test_fen("k7/8/1P6/8/8/8/8/7K b - - 0 1", 1, [2])
    @test test_fen("k7/1P6/8/8/8/8/8/7K b - - 0 1", 1, [3])
    @test test_fen("k7/8/8/8/8/2P5/1P6/7K w - - 0 1", 1, [6])
end
