using Test
using Bobby

function test_fen(fen, depth, result)
    b = Bobby.fen_to_bitboard(fen)
    pt = Bobby.perft(b, depth, b.player_color)
    if pt.nodes == result
        return true
    else
        return false
    end
end

@testset "parser.jl" begin
    include("test_parser.jl")
end

@testset "converters.jl" begin
    include("test_converters.jl")
end

@testset "nights.jl" begin
    include("test_nights.jl")
end

@testset "king.jl" begin
    include("test_king.jl")
end

@testset "rooks.jl" begin
    include("test_rooks.jl")
end

@testset "bishops.jl" begin
    include("test_bishops.jl")
end

@testset "queen.jl" begin
    include("test_queen.jl")
end

@testset "pawns.jl" begin
    include("test_pawns.jl")
end

@testset "check.jl" begin
    include("test_check.jl")
end

@testset "perft.jl" begin
    include("test_perft.jl")
end
