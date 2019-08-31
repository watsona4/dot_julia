module BitConverter

export bytes, to_big, to_int

"""
    bytes(x::Integer; len::Integer, little_endian::Bool)
    -> Vector{len, UInt8}

Convert an Integer `x` to a Vector{UInt8}
Options (not available for `x::BigInt`):
- `len` to define a minimum Vector lenght in bytes, result will show no leading
zero by default.
- set `little_endian` to `true` for a result in little endian byte order, result
in big endian order by default.


    julia> bytes(32974)
    2-element Array{UInt8,1}:
     0x80
     0xce

    julia> bytes(32974, len=4)
    4-element Array{UInt8,1}:
     0x00
     0x00
     0x80
     0xce

    julia> bytes(32974, little_endian=true)
    2-element Array{UInt8,1}:
     0xce
     0x80

"""
function bytes(x::Integer; len::Integer=0, little_endian::Bool=false)
    result = reinterpret(UInt8, [hton(x)])
    i = findfirst(x -> x != 0x00, result)
    if len != 0
        i = length(result) - len + 1
    end
    result = result[i:end]
    if little_endian
        reverse!(result)
    end
    return result
end

function bytes(x::BigInt)
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
    Int(x::Vector{UInt8}; little_endian::Bool)
    -> Integer

Convert a Vector{UInt8} an Integer, a BigInt above 64 bits
Optionally set `little_endian` to `true` if the input as such byte order,
input is considered big endian by default.


    julia> Int([0x01, 0x00])
    256

    julia> Int([0x01, 0x00], little_endian=true)
    1

"""
function to_int(x::Vector{UInt8}; little_endian::Bool=false)
    if length(x) > 8
        to_big(x)
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
    to_big(x::Vector{UInt8}) -> BigInt

Convert a Vector{UInt8} of any lenght to a BigInt.
Considers the input a big endian.


    julia> to_big([0x01, 0x00])
    256

"""
function to_big(x::Vector{UInt8})
    hex = bytes2hex(x)
    return parse(BigInt, hex, base=16)
end

end # module

@deprecate Int(x::Vector{UInt8}; little_endian::Bool) to_int(x; little_endian=little_endian)
@deprecate big(x::Vector{UInt8}) to_big(x)
