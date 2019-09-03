__precompile__()
module REPLTetris

using Crayons, Compat
export tetris

include("../Terminal.jl/Terminal.jl")
using .Terminal

include("tiles.jl")
include("board.jl")
include("printboard.jl")
include("actions.jl")

function tetris(board = Board())
    rawmode() do
        clear_screen()
        update_board!(board)
        abort = [false]
        @async while !abort[1] && add_tile!(board)
            board.allowhold = true
            print_preview(board)
            print_hold(board)
            while !abort[1] && drop!(board)
                sleep((0.8 - (board.level-1) * 0.007)^(board.level-1))
            end
            delete_lines!(board)
        end

        while !abort[1]
            c = readKey()
            c in ["Up", "x"]    && rot_right!(board)
            c in ["Down"]       && drop!(board)
            c in ["Right"]      && move_right!(board)
            c in ["Left"]       && move_left!(board)
            c in [" "]          && fast_drop!(board)
            c in ["Ctrl", "z"]  && rot_left!(board)
            c in ["c"]          && hold!(board)
            c in ["Ctrl-C"]     && (abort[1]=true)
        end
    end
end

end #module
