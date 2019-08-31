function star_attack(board::UInt64, ui::UInt64)
    free_squares, edge_squares = orthogonal_attack(board, ui)
    free_squares, edge_squares  = cross_attack(free_squares, edge_squares,
        board, ui)

    return free_squares, edge_squares
end

function star_attack(free_squares::Array{UInt64,1},
    edge_squares::Array{UInt64,1}, occ::UInt64, ui::UInt64)
    free_squares, edge_squares = orthogonal_attack(free_squares, edge_squares,
        occ, ui)
    free_squares, edge_squares = cross_attack(free_squares, edge_squares, occ,
        ui)

    return free_squares, edge_squares
end
