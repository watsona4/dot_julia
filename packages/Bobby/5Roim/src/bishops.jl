function slide_diagonal(free_squares::Array{UInt64,1},
    edge_squares::Array{UInt64,1}, occ::UInt64, ui::UInt64)

    for i in 1:15
        if DIAGONALS[i] & ui != EMPTY
            return slide(free_squares, edge_squares, occ,
                ui, 9, DIAGONALS[i])
        end
    end
end


function slide_antidiagonal(free_squares::Array{UInt64,1},
    edge_squares::Array{UInt64,1}, occ::UInt64, ui::UInt64)

    for i in 1:15
        if ANTIDIAGONALS[i] & ui != EMPTY
            return slide(free_squares, edge_squares, occ,
                ui, 7, ANTIDIAGONALS[i])
        end
    end
end


function cross_attack(occ::UInt64, ui::UInt64)
    free_squares = Array{UInt64,1}()
    edge_squares = Array{UInt64,1}()

    free_squares, edge_squares = slide_diagonal(free_squares, edge_squares,
        occ, ui)
    free_squares, edge_squares = slide_antidiagonal(free_squares, edge_squares,
        occ, ui)

    return free_squares, edge_squares
end


function cross_attack(free_squares::Array{UInt64,1},
    edge_squares::Array{UInt64,1}, occ::UInt64, ui::UInt64)

    free_squares, edge_squares = slide_diagonal(free_squares, edge_squares,
        occ, ui)
    free_squares, edge_squares = slide_antidiagonal(free_squares, edge_squares,
        occ, ui)

    return free_squares, edge_squares
end


function gen_all_diagonal_masks()
    diag_masks = Dict{UInt64, UInt64}()
    for i = 1:64
        ui = INT2UINT[i]
        diag_mask = EMPTY
        for j = 1:15
            if ui & DIAGONALS[j] != EMPTY
                diag_mask |= DIAGONALS[j]
                break
            end
        end
        for k = 1:15
            if ui & ANTIDIAGONALS[k] != EMPTY
                diag_mask |= ANTIDIAGONALS[k]
                break
            end
        end
        diag_masks[ui] = diag_mask
    end
    return diag_masks
end
const DIAG_MASKS = gen_all_diagonal_masks()
