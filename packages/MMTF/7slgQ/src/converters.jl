include("constants.jl")
include("utils.jl")

"""
Convert a byte array into an integer array. The number of bytes forming an integer
is defined by num
in_bytes: the input bytes
num: the number of bytes per int
"""
function ints(in_bytes::Array{UInt8,1}, num)
    out_arr = Int[]
    if num == 1
        out_arr = htonofarray(reinterpret(Int8,in_bytes))
    elseif num == 2
        out_arr = htonofarray(reinterpret(Int16,in_bytes))
    elseif num == 4
        out_arr = htonofarray(reinterpret(Int32,in_bytes))
    else
        throw(ArgumentError("Cannot convert bytes to integer array. Number of bytes parsed is wrong"))
    end    
    return out_arr
end

"""
Convert floating points to integers using a multiplier.
in_floats: the input floats
multiplier: the multiplier to be used for conversion. Corresponds to the precisison.
"""
function ints(in_floats::Array{Float32,1}, multiplier)
    return Int32[Int32(round(x * multiplier)) for x in in_floats]
end

"""
Convert an array of chars to an array of ints.
"""
function ints(in_chars::Array{Char,1})
    return Int32[Int32(x) for x in in_chars]
end

"""
Convert an integer array into a byte arrays.
"""
function bytes(in_ints::Array{T,1}) where {T<:Integer}
    out_array=UInt8[]
    return append!(out_array,reinterpret(UInt8,ntohofarray(in_ints)))
end

"""
Convert integers to floats by division.
in_ints: the integer array
divider: the divider
"""
function floats(in_ints::Array{T,1}, divider) where {T<:Integer}
    return Float32[x/divider for x in in_ints]
end

"""
Convert integers to chars.
"""
function chars(in_ints::Array{T,1}) where {T<:Integer}
    return Char[Char(x) for x in in_ints]
end

"""
Convert a list of bytes to a list of strings. Each string is of length mmtf.CHAIN_LEN
"""
function decodechainlist(in_bytes::Array{UInt8,1})
    tot_strings = div.(length(in_bytes),CHAIN_LEN)
    out_strings = String[]
    for i=1:tot_strings
        out_s = in_bytes[(i*CHAIN_LEN)-(CHAIN_LEN-1) : i * CHAIN_LEN]
        stripped_s = strip(String(out_s),NULL_BYTE)
        push!(out_strings,String(stripped_s))
    end
    return out_strings
end

"""
Convert a list of strings to a list of byte arrays.
"""
function encodechainlist(in_strings::Array{String,1})
    out_bytes=UInt8[]
    for in_s in in_strings
        append!(out_bytes, transcode(UInt8,in_s))
        for i=1:(CHAIN_LEN - length(in_s))
            append!(out_bytes, transcode(UInt8,"$(NULL_BYTE)"))
        end
    end
    return out_bytes
end

"""
Unpack an array of integers using recursive indexing.
"""
function recursiveindexdecode(int_array::Array{Int16,1})
    out_arr = Int32[]
    encoded_ind = 1
    while encoded_ind <= length(int_array)
        decoded_val = 0
        while int_array[encoded_ind]==MAX_SHORT || int_array[encoded_ind]==MIN_SHORT
            decoded_val += int_array[encoded_ind]
            encoded_ind+=1
            if int_array[encoded_ind]==0
                break
            end
        end
        decoded_val += int_array[encoded_ind]
        encoded_ind+=1
        push!(out_arr,Int32(decoded_val))
    end
    return out_arr
end

"""
Pack an integer array using recursive indexing.
"""
function recursiveindexencode(int_array::Array{Int32,1})
    out_arr = Int16[]
    for curr in int_array
        if curr >= 0 
            while curr >= MAX_SHORT
                push!(out_arr,MAX_SHORT)
                curr -=  MAX_SHORT
            end
        else
            while curr <= MIN_SHORT
                push!(out_arr,MIN_SHORT)
                curr += Int(abs(MIN_SHORT))
            end
        end
        push!(out_arr, Int16(curr))
    end
    return out_arr
end