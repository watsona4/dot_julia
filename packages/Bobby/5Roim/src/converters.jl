function cvt_to_binary_string(i::Int64)
	return bitstring(i)
end


function cvt_to_binary_string(ui::UInt64)
	return bitstring(ui)
end


function cvt_to_int(binary_string::String)
    return parse(UInt64, binary_string; base=2)
end


function cvt_to_int(ui::UInt64)
    return cvt_to_int(cvt_to_binary_string(ui))
end


function cvt_to_binary_string(bit_array::BitArray{1})
    binary_string = ""
    for i in 1:length(bit_array)
        if bit_array[i]
            binary_string *= "1"
        else
            binary_string *= "0"
        end
    end
    return binary_string
end


function cvt_to_uint(pieces_array::Array{UInt64,1})
    pieces_uint = UInt64(0)
    for piece in pieces_array
        pieces_uint |= piece
    end
    return pieces_uint
end


function cvt_to_uint(binary_string::String)
    return UInt(cvt_to_int(binary_string))
end


function cvt_to_uint(i::Int64)
    return UInt(i)
end


function cvt_to_uint(bit_array::BitArray{1})
    return cvt_to_uint(cvt_to_binary_string(bit_array))
end


function cvt_to_bitarray(pieces_array::Array{UInt64,1})
    return cvt_to_bitarray(cvt_to_uint(pieces_array))
end


function cvt_to_bitarray(i::UInt64)
    return cvt_to_bitarray(cvt_to_binary_string(i))
end


function cvt_to_bitarray(s::String)
    bit_array = falses(64)
    for i = 1:64
        if s[i] == '1'
            bit_array[i] = true
        end
    end
    return bit_array
end


# julia> Bobby.generate_pgn_square_to_uint()
# Dict{String,UInt64} with 64 entries:
#   "d7" => 0x0010000000000000
#   "e4" => 0x0000000008000000
#   ⋮    => ⋮
function gen_pgn_square_to_uint_dict()
    pgn_squares = Dict{String,UInt64}()

    i = 0
    for rank in 8:-1:1
        for file in 1:8
           square = "0"^i * "1" * "0"^(63 - i)
           square_int = cvt_to_int(square)
           pgn_coordinate = string(Char(Int('a')+(file - 1))) * string(rank)
           push!(pgn_squares, pgn_coordinate=>square_int)
           i += 1
        end
    end

    return pgn_squares
end
const PGN2UINT = gen_pgn_square_to_uint_dict()


# julia> squares = Bobby.generate_pgn_square_to_int()
# Dict{String,Int64} with 64 entries:
#   "d7" => 11
#   "a5" => 24
#   ⋮    => ⋮
function gen_pgn_square_to_int_dict()
    pgn_squares = Dict{String,Int64}()
    int_squares = Dict{Int64,String}()

    i = 1
    for rank in 8:-1:1
        for file in 1:8
           pgn_coordinate = string(Char(Int('a')+(file - 1))) * string(rank)
           push!(pgn_squares, pgn_coordinate=>i)
           push!(int_squares, i=>pgn_coordinate)
           i += 1
        end
    end

    return pgn_squares, int_squares
end
const PGN2INT, INT2PGN = gen_pgn_square_to_int_dict()
const A1 = PGN2UINT["a1"]
const B1 = PGN2UINT["b1"]
const C1 = PGN2UINT["c1"]
const D1 = PGN2UINT["d1"]
const E1 = PGN2UINT["e1"]
const F1 = PGN2UINT["f1"]
const G1 = PGN2UINT["g1"]
const H1 = PGN2UINT["h1"]
const A8 = PGN2UINT["a8"]
const B8 = PGN2UINT["b8"]
const C8 = PGN2UINT["c8"]
const D8 = PGN2UINT["d8"]
const E8 = PGN2UINT["e8"]
const F8 = PGN2UINT["f8"]
const G8 = PGN2UINT["g8"]
const H8 = PGN2UINT["h8"]


# julia> Bobby.generate_int_to_uint()
# Dict{Int64,UInt64} with 64 entries:
#   2  => 0x4000000000000000
#   11 => 0x0020000000000000
#   ⋮  => ⋮
function gen_int_to_uint_dict()
    squares_int_uint = Dict{Int64,UInt64}()

    for k in keys(PGN2INT)
        push!(squares_int_uint, PGN2INT[k]=>PGN2UINT[k])
    end

    return squares_int_uint
end
const INT2UINT = gen_int_to_uint_dict()


function gen_uint_to_pgn_dict()
    uint_pgn = Dict{UInt64,String}()

    for k in keys(INT2PGN)
        push!(uint_pgn, INT2UINT[k] => INT2PGN[k])
    end
    return uint_pgn
end
const UINT2PGN = gen_uint_to_pgn_dict()


function change_color(color::String)
    if color == "white"
        return "black"
    else
        return "white"
    end
end
