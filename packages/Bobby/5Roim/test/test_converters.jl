@testset "converters" begin
    i = Bobby.cvt_to_int(
        "0000000000000000000000000000000000000000000000000000000000000001")
    @test i == 0x0000000000000001

    s = Bobby.cvt_to_binary_string(0x0000000000000001)
    @test (s == 
      "0000000000000000000000000000000000000000000000000000000000000001")

    s = Bobby.cvt_to_binary_string(1)
    @test (s == 
      "0000000000000000000000000000000000000000000000000000000000000001")

    b = Bobby.set_board()
    u = Bobby.cvt_to_uint(b.p)
    @test u == 0x00ff000000000000

    white_pawns = [0,0,0,0,0,0,0,0,
                   0,0,0,0,0,0,0,0,
                   0,0,0,0,0,0,0,0,
                   0,0,0,0,0,0,0,0,
                   0,0,0,0,0,0,0,0,
                   0,0,0,0,0,0,0,0,
                   1,1,1,1,1,1,1,1,
                   0,0,0,0,0,0,0,0]
    ba = Bobby.cvt_to_bitarray(b.P)
    @test Int.(ba) == white_pawns

    squares_uint = Bobby.gen_pgn_square_to_uint_dict()
    @test haskey(squares_uint, "e2")
    @test squares_uint["e2"] == 0x0000000000000800

    squares_int, squares_pgn = Bobby.gen_pgn_square_to_int_dict()
    @test haskey(squares_int, "e2")
    @test haskey(squares_pgn, 1)
    @test squares_int["a8"] == 1
    @test squares_pgn[1] == "a8"

    squares_int_uint = Bobby.gen_int_to_uint_dict()
    @test haskey(squares_int_uint, 1)
    @test squares_int_uint[2] == 0x4000000000000000

    color = "white"
    c = Bobby.change_color(color)
    @test c == "black"
end
