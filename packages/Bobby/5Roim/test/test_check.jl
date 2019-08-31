@testset "check" begin
    b = Bobby.set_board()

    @test !Bobby.king_in_check(b)
    @test !Bobby.king_in_check(b, "black")

    @test test_fen("k7/8/8/8/8/8/5PPP/r6K w KQkq - 0 1", 1, [0])
    @test test_fen("k7/8/8/8/8/8/5PPP/rq5K w KQkq - 0 1", 1, [0])
    @test test_fen("k7/8/8/8/8/8/5PPP/rq5K w KQkq - 0 1", 1, [0])
    @test test_fen("k7/8/8/8/8/6Pb/5PqP/5rRK w KQkq - 0 1", 1, [0])
    @test test_fen("k7/8/8/8/8/5qP1/5PbP/5rRK w Q - 0 1", 1, [0])
    @test test_fen("k7/8/8/8/8/5bP1/5PpP/5rRK w Q - 0 1", 1, [0])
    @test test_fen("k2R4/ppp5/8/8/8/8/8/7K b Q - 0 1", 1, [0])
    @test test_fen("k2Q4/ppp5/8/8/8/8/8/7K b Q -", 1, [0])
    @test test_fen("k7/pQp5/2B5/8/8/8/8/7K b Q -", 1, [0])
    @test test_fen("k7/pQp5/2P5/8/8/8/8/7K b Q -", 1, [0])
    @test test_fen("k7/pPp5/N1P5/8/8/8/8/7K b Q -", 1, [0])
    @test test_fen("k7/pPpN4/2P5/8/8/8/8/7K b Q -", 1, [0])
    @test test_fen("k7/p1p5/P1P5/8/8/8/8/1R5K b Q -", 1, [0])
    @test test_fen("k7/p1pN4/P1P5/8/8/8/8/7K b Q -", 1, [0])
end