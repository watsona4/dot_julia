"""
    Integer, Integer, Boolean -> Array{UInt8,1}

Convert Integer to an Array{UInt8}
"""
function int2bytes(x::Integer, l::Integer=0, little_endian::Bool=false)
    result = reinterpret(UInt8, [hton(x)])
    i = findfirst(x -> x != 0x00, result)
    if l != 0
        i = length(result) - l + 1
    end
    result = result[i:end]
    if little_endian
        reverse!(result)
    end
    return result
end

"""
    BigInt -> Array{UInt8,1}

Convert BigInt to an Array{UInt8}
"""
function int2bytes(x::BigInt)
    n_bytes_with_zeros = x.size * sizeof(Sys.WORD_SIZE)
    uint8_ptr = convert(Ptr{UInt8}, x.d)
    n_bytes_without_zeros = 1

    if ENDIAN_BOM == 0x04030201
        # the minimum should be 1, else the result array will be of
        # length 0
        for i in n_bytes_with_zeros:-1:1
            if unsafe_load(uint8_ptr, i) != 0x00
                n_bytes_without_zeros = i
                break
            end
        end

        result = Array{UInt8}(undef, n_bytes_without_zeros)

        for i in 1:n_bytes_without_zeros
            @inbounds result[n_bytes_without_zeros + 1 - i] = unsafe_load(uint8_ptr, i)
        end
    else
        for i in 1:n_bytes_with_zeros
            if unsafe_load(uint8_ptr, i) != 0x00
                n_bytes_without_zeros = i
                break
            end
        end

        result = Array{UInt8}(undef, n_bytes_without_zeros)

        for i in 1:n_bytes_without_zeros
            @inbounds result[i] = unsafe_load(uint8_ptr, i)
        end
    end
    return result
end

"""
    Array{UInt8,1}, Boolean -> Integer

Convert Array{UInt8,1} to an Integer
"""
function bytes2int(x::Array{UInt8,1}, little_endian::Bool=false)
    if length(x) > 8
        bytes2big(x)
    else
        missing_zeros = div(Sys.WORD_SIZE, 8) -  length(x)
        if missing_zeros > 0
            if little_endian
                for i in 1:missing_zeros
                    push!(x,0x00)
                end
            else
                for i in 1:missing_zeros
                    pushfirst!(x,0x00)
                end
            end
        end
        if ENDIAN_BOM == 0x04030201 && little_endian
        elseif ENDIAN_BOM == 0x04030201 || little_endian
            reverse!(x)
        end
        return reinterpret(Int, x)[1]
    end
end

"""
    Array{UInt8,1} -> BigInt

Convert Array{UInt8,1} to an Integer
"""
function bytes2big(x::Array{UInt8,1})
    hex = bytes2hex(x)
    return parse(BigInt, hex, base=16)
end

# Alternative implementation

# function bytes2int2(x::Array{UInt8,1})
#     if isempty(x)
#         return 0
#     end
#     if length(x) > div(Sys.WORD_SIZE, 8)
#         T = BigInt
#     else
#         T = Int
#     end
#     result = zero(T)
#     if ENDIAN_BOM == 0x01020304
#         reverse!(x)
#     end
#     for c in x
#         result <<= 8
#         result += c
#     end
#     return result
# end
#
# function faster_bytes2big(x::Array{UInt8,1})
#     xsize = cld(length(x), Base.GMP.BITS_PER_LIMB / 8)
#     if ENDIAN_BOM == 0x04030201
#         reverse!(x)
#     end
#     result = Base.GMP.MPZ.realloc2(xsize * Base.GMP.BITS_PER_LIMB)
#     result.size = xsize
#     unsafe_copyto!(result.d, convert(Ptr{Base.GMP.Limb}, pointer(x)), xsize)
#     return result
# end
