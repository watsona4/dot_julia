# Alternative implementation

function to_int(x::Vector{UInt8})
    if isempty(x)
        return 0
    end
    if length(x) > div(Sys.WORD_SIZE, 8)
        T = BigInt
    else
        T = Int
    end
    result = zero(T)
    if ENDIAN_BOM == 0x01020304
        reverse!(x)
    end
    for c in x
        result <<= 8
        result += c
    end
    return result
end

function faster_big(x::Vector{UInt8})
    xsize = cld(length(x), Base.GMP.BITS_PER_LIMB / 8)
    if ENDIAN_BOM == 0x04030201
        reverse!(x)
    end
    result = Base.GMP.MPZ.realloc2(xsize * Base.GMP.BITS_PER_LIMB)
    result.size = xsize
    unsafe_copyto!(result.d, convert(Ptr{Base.GMP.Limb}, pointer(x)), xsize)
    return result
end
