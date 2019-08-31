@testset "knights" begin
    b = Bobby.set_board()
    
    nv = Bobby.gen_night_valid(Bobby.INT2UINT[58])
    @test length(nv) == 3
    nvw = [0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0,
           1,0,1,0,0,0,0,0,
           0,0,0,1,0,0,0,0,
           0,0,0,0,0,0,0,0]
    @test all(Int.(Bobby.cvt_to_bitarray(nv)) .== nvw)
    
    anv = Bobby.gen_all_night_valid_moves()
    @test all(Int.(Bobby.cvt_to_bitarray(anv[Bobby.INT2UINT[58]])) .== nvw)

    @test test_fen("k7/8/8/8/8/8/8/N6K w - - 0 1", 1, [5])
    @test test_fen("k7/8/8/8/8/8/1N6/7K w - - 0 1", 1, [7])
    @test test_fen("k7/8/8/8/P1P5/3P4/1N6/7K w - - 0 1", 1, [7])
    @test test_fen("k7/8/8/8/p1p5/3p4/1N6/7K w - - 0 1", 1, [7])
    @test test_fen("k7/8/8/8/3n4/8/2P1P3/7K b - - 0 1", 1, [11])
    @test test_fen("k7/8/8/3n4/1p3p2/1Pp1pP2/2P1P3/7K b - - 0 1", 1, [7])
end
