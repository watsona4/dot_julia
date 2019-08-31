function validate_uci_move(uci_move::String)
    if  ~occursin(r"[a-h][1-8] [a-h][1-8]", uci_move)
        println("wrong move format, try again")
        return false
    end
    return true
end


function ask_for_move()
    while true
        println("Enter move:")
        user_move = readline(stdin)
        if validate_uci_move(user_move)
            return split(user_move, ' ')
        end
    end
    return "xx xx"
end


function play(human_color::String="white")
    b = set_board()
    check = false

    while true
        pretty_print(b)

        moves = get_all_valid_moves(b, b.player_color)
        if length(moves) == 0
            if check
                println("check mate!")
                return
            else
                println("stalemate...")
                return
            end
        end
        println(b.player_color," to move")

        if b.player_color == human_color
            while true
                s, t = ask_for_move()
                for move in moves
                    if move.source == PGN2UINT[s] && move.target == PGN2UINT[t]
                        b = move_piece(b, move, b.player_color)
                        b = update_attacked(b)
                        b = update_castling_rights(b)
                        @goto next_move
                    end
                end
                println("Move not available, try again")
            end
        else
            b = move_piece(b, moves[rand(1:length(moves))], b.player_color)
            b = update_attacked(b)
            b = update_castling_rights(b)
        end
        
        @label next_move
        b.player_color = change_color(b.player_color)
        if king_in_check(b, b.player_color)
            check = true
            println("check!")
        end
    end
end
