function ugly_print(i::UInt64)
    bit_array = cvt_to_bitarray(i)
    uglyPrint(bit_array)
end


function ugly_print(pieces_array::Array{UInt64,1})
    pieces_uint = cvt_to_uint(pieces_array)
    ugly_print(pieces_uint)
end


function ugly_print(valid_moves::Array{Any,1})
    pieces = EMPTY
    for move in valid_moves
        pieces |= move[2]
    end
    ugly_print(pieces)
end


function uglyPrint(b::BitArray)

    r_b = Int.(transpose(reshape(b, 8, :)))
    ranks = ["8", "7", "6", "5", "4", "3", "2", "1"]

    @printf("\n  o-----------------o\n")
    for i = 1:8
        @printf("%s | ", ranks[i])
        for j = 1:8
            @printf("%d ", r_b[i,j])
        end
        @printf("|\n")
    end
    @printf("  o-----------------o\n")
    @printf("    a b c d e f g h\n")
end


function pretty_print(board::Bitboard, player_color::String="white")
    ranks = ["8", "7", "6", "5", "4", "3", "2", "1"]
    
    free = transpose(reshape(cvt_to_bitarray(board.free), 8, :))
    taken = transpose(reshape(cvt_to_bitarray(board.taken), 8, :))

    p = transpose(reshape(cvt_to_bitarray(board.p), 8, :))
    r = transpose(reshape(cvt_to_bitarray(board.r), 8, :))
    n = transpose(reshape(cvt_to_bitarray(board.n), 8, :))
    b = transpose(reshape(cvt_to_bitarray(board.b), 8, :))
    q = transpose(reshape(cvt_to_bitarray(board.q), 8, :))
    k = transpose(reshape(cvt_to_bitarray(board.k), 8, :))
    P = transpose(reshape(cvt_to_bitarray(board.P), 8, :))
    R = transpose(reshape(cvt_to_bitarray(board.R), 8, :))
    N = transpose(reshape(cvt_to_bitarray(board.N), 8, :))
    B = transpose(reshape(cvt_to_bitarray(board.B), 8, :))
    Q = transpose(reshape(cvt_to_bitarray(board.Q), 8, :))
    K = transpose(reshape(cvt_to_bitarray(board.K), 8, :))
    white = transpose(reshape(cvt_to_bitarray(board.white), 8, :))
    black = transpose(reshape(cvt_to_bitarray(board.black), 8, :))
    
    pieces = Dict("pawn"=>" o",
        "rook"=>" Π",
        "knight"=>" ζ",
        "bishop"=>" Δ",
        "queen"=>" Ψ",
        "king"=>" +")
    # pieces = Dict("pawn"=>" o",
    #   "rook"=>" R",
    #   "knight"=>" N",
    #   "bishop"=>" B",
    #   "queen"=>" Q",
    #   "king"=>" K")
    labels = ["pawn", "knight", "bishop", "rook", "queen", "king"]

    @printf("\n  o-------------------------o\n")
    
    if player_color == "white"
        idxs = 1:8
    else
        idxs = 8:-1:1
    end

    bgc = "w"
    for i in idxs
        @printf(Crayon(reset=true), "%s | ", ranks[i])
        for j in idxs
            if free[i,j]
                if bgc == "w"
                    @printf(Crayon(reset=true, background=:dark_gray), "   ")
                    bgc = "b"
                else
                    @printf(Crayon(reset=true, background=:default), "   ")
                    bgc = "w"
                end
            else
                if black[i,j]
                    if p[i,j]
                        c = pieces["pawn"]
                    elseif r[i,j]
                        c = pieces["rook"]
                    elseif n[i,j]
                        c = pieces["knight"]
                    elseif b[i,j]
                        c = pieces["bishop"]
                    elseif q[i,j]
                        c = pieces["queen"]
                    elseif k[i,j]
                        c = pieces["king"]
                    else
                        error("Black piece not found")
                    end
                    color = :light_magenta
                else
                    if P[i,j]
                        c = pieces["pawn"]
                    elseif R[i,j]
                        c = pieces["rook"]
                    elseif N[i,j]
                        c = pieces["knight"]
                    elseif B[i,j]
                        c = pieces["bishop"]
                    elseif Q[i,j]
                        c = pieces["queen"]
                    elseif K[i,j]
                        c = pieces["king"]
                    else
                        error("White piece not found")
                    end
                    color = :light_cyan
                end
                if bgc == "w"
                    @printf(Crayon(bold=true, foreground=color,
                        background=:dark_gray), "%s ", c)
                    bgc = "b"
                else
                    @printf(Crayon(bold=true, foreground=color,
                        background=:default), "%s ", c)
                    bgc = "w"
                end
                
            end
        end
        
        if i > 1 && i < 8
            label = labels[i-1]
            piece = pieces[label]
            @printf(Crayon(reset=true), "| %s %s \n", piece, label)
        else
            @printf(Crayon(reset=true), "|\n")
        end
        if bgc == "w"
            bgc = "b"
        else
            bgc = "w"
        end
    end
    @printf(Crayon(reset=true), "  o-------------------------o\n")

    if player_color == "white"
        @printf("     a  b  c  d  e  f  g  h\n")
    else
        @printf("     h  g  f  e  d  c  b  a\n")
    end
end
