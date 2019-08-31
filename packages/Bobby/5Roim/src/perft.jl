mutable struct PerftTree
    nodes :: Array{Int64,1}
    divide :: Dict{String,Int64}
end


function perft(board, depth, color::String="white")

    pt = PerftTree(zeros(depth), Dict{String,Int64}())

    return explore(pt, board, depth, 1, color)
end


function print_perftree(pt::PerftTree)
    println("Nodes      ", pt.nodes)
    for x in sort(collect(pt.divide))
        println(x)
    end
end


function sumdivide(pt::PerftTree)
    c = 0
    for k in keys(pt.divide)
        c += pt.divide[k]
    end
    println(c)
end


function explore(pt::PerftTree, board::Bitboard,
    max_depth::Int64, depth::Int64, color::String="white",
    move_name::String="")

    moves = get_all_valid_moves(board, color)

    if length(moves) == 0

        return pt
    end

    if depth == 1
        for m in moves
            push!(pt.divide,
                m.piece_type*"-"*UINT2PGN[m.source]*UINT2PGN[m.target]=>0)
        end
    end

    if depth > max_depth
        return pt
    end

    pt.nodes[depth] += length(moves)

    if depth >= max_depth && depth > 1
        pt.divide[move_name] += length(moves)
        return pt
    end

    new_color = change_color(color)
    c = 1
    for m in moves
        newb = deepcopy(board)
        newb = move_piece(newb, m, color)
        newb = update_attacked(newb)
        newb = update_castling_rights(newb)

        if depth == 1
            move_name = m.piece_type*"-"*UINT2PGN[m.source]*UINT2PGN[m.target]
        else
            pt.divide[move_name] += 1
        end

        pt = explore(pt, newb, max_depth, depth+1, new_color, move_name)
    end

    return pt
end
