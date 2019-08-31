@testset "perft1" begin
    b = Bobby.set_board()
    pt = Bobby.perft(b, 4, b.player_color)
    @test pt.nodes == [20, 400, 8902, 197281]
end

@testset "perft2" begin
    @test test_fen(
        "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 1 1",
         2, [48, 2039])
    # [48, 2039, 97862, 4085603]
end

@testset "perft3" begin
    @test test_fen("8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 1 1", 2, [14, 191])
    # [14, 191, 2812, 43238]
end

@testset "perft4" begin
    @test test_fen(
        "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1",
        2, [6, 264])
    # [6, 264, 9467, 422333]
end

@testset "perft4.1" begin
    @test test_fen(
        "r2q1rk1/pP1p2pp/Q4n2/bbp1p3/Np6/1B3NBn/pPPP1PPP/R3K2R b KQ - 0 1",
        2, [6, 264])
    # [6, 264, 9467, 422333]
end

@testset "perft5" begin
    @test test_fen(
        "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8",
        2, [44, 1486])
    # [44, 1486, 62379, 2103487]
end

@testset "perft6" begin
    @test test_fen(
        "r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1"*
        " w - - 0 10",
        2, [46, 2079])
    # [46, 2079, 89890, 3894594]
end

@testset "perft7" begin
    @test test_fen(
        "r3k2r/1bp2pP1/5n2/1P1Q4/1pPq4/5N2/1B1P2p1/R3K2R b KQkq c3 0 1",
        2, [60, 2608])
    # [60, 2608, 113742, 4812099]
end
