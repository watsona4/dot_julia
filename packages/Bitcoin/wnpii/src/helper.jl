"""
Double sha256 function
"""
function hash256(x::Vector{UInt8})
    return sha256(sha256(x))
end

"""
read_varint reads a variable integer from a stream
"""
 function read_varint(s::Base.GenericIOBuffer{Vector{UInt8}})
     i = UInt8[]
     readbytes!(s, i, 1)
     if i == [0xfd]
         # 0xfd means the next two bytes are the number
         readbytes!(s, i, 2)
         return reinterpret(Int16, i)[1]
     elseif i == [0xfe]
         # 0xfe means the next four bytes are the number
         readbytes!(s, i, 4)
         return reinterpret(Int32, i)[1]
     elseif i == [0xff]
         # 0xff means the next eight bytes are the number
         readbytes!(s, i, 8)
         return reinterpret(Int64, i)[1]
     else
         # anything else is just the integer
         return Int(i[1])
     end
 end

"""
Encodes an integer as a varint
"""
 function encode_varint(n::Integer)
    if n < 0xfd
        return [UInt8(n)]
    elseif n < 0x10000
        return prepend!(bytes(n, len=2, little_endian=true), [0xfd])
    elseif n < 0x100000000
        return prepend!(bytes(n, len=4, little_endian=true), [0xfe])
    elseif n < 0x10000000000000000
        return prepend!(bytes(n, len=8, little_endian=true), [0xff])
    else
        error("Integer, ", n, " is too large")
    end
 end

struct VarString <: AbstractString
    len::Integer
    str::String
    VarString(str::String) = new(length(str), str)
end

serialize(x::VarString) = append!(encode_varint(x.len), x.str)

io2varstring(io::IOBuffer) = VarString(String(read(io, read_varint(io))))

"""
    bytes2flags(bytes::Vector{UInt8}) -> Vector{Bool}

Returns an Vector{Bool} representing bits
"""
function bytes2flags(bytes::Vector{UInt8})
    result = Bool[]
    for byte in bytes
        for i in 0:7
            push!(result, (byte & (0x01 << i)) != 0)
        end
    end
    result
end

"""
    bytes2flags(bytes::Vector{UInt8}) -> Vector{Bool}

Returns an Vector{Bool} representing bits
"""
function flags2bytes(flags::Vector{Bool})
    if mod(length(flags), 8) != 0
        error("flags does not have a length that is divisible by 8")
    end
    result = fill(0x00, fld(length(flags), 8))
    i = 0
    for flag in flags
        byte_index, bit_index = fldmod(i, 8)
        if flag
            result[byte_index + 1] |= (1 << bit_index)
        end
        i += 1
    end
    result
end

# @deprecate read_varint(s::Base.GenericIOBuffer{Vector{UInt8}}) read(io::IOBuffer)::CompactSizeUInt
# @deprecate encode_varint(n::Integer) serialize(n::CompactSizeUInt)
