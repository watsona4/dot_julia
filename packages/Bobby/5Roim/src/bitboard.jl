mutable struct Bitboard
    white :: UInt64 # all white pieces
    P :: Array{UInt64,1}
    R :: Array{UInt64,1}
    N :: Array{UInt64,1}
    B :: Array{UInt64,1}
    Q :: Array{UInt64,1}
    K :: UInt64
    A :: Array{UInt64,1}

    black :: UInt64 # all black pieces
    p :: Array{UInt64,1}
    r :: Array{UInt64,1}
    n :: Array{UInt64,1}
    b :: Array{UInt64,1}
    q :: Array{UInt64,1}
    k :: UInt64
    a :: Array{UInt64,1}

    free :: UInt64  # all free squares
    taken :: UInt64 # all pieces

    white_attacks :: UInt64 # attacked squares
    black_attacks :: UInt64

    player_color :: String

    white_can_castle_queenside :: Bool
    white_can_castle_kingside  :: Bool
    black_can_castle_queenside :: Bool
    black_can_castle_kingside  :: Bool
    white_king_moved :: Bool
    black_king_moved :: Bool

    enpassant_square :: UInt64
    enpassant_done :: Bool

    halfmove_clock :: Int64
    fullmove_clock :: Int64 # start at 1, increment for each black move

    fen :: String
    game :: Array{String,1}
end


function set_board()
    return fen_to_bitboard(
        "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
end
