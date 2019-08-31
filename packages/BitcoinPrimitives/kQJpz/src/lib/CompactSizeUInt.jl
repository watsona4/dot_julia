# Copyright (c) 2019 Simon Castano
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

"""
The raw transaction format and several peer-to-peer network messages use a type
of variable-length integer to indicate the number of bytes in a following piece
of data.
Bitcoin Core code refers to these variable length integers as compactSize.
Many other documents refer to them as var_int or varInt, but this risks
conflation with other variable-length integer encodings—such as the CVarInt
class used in Bitcoin Core for serializing data to disk. Because it’s used in
the transaction format, the format of compactSize unsigned integers is part of
the consensus rules.
For numbers from 0 to 252, compactSize unsigned integers look like regular
unsigned integers. For other numbers up to 0xffffffffffffffff, a byte is
prefixed to the number to indicate its length—but otherwise the numbers look
like regular unsigned integers in little-endian order.


Value                                    | Bytes Used  | Format
-----------------------------------------|-------------|-----------------------------------------
>= 0 && <= 252                           | 1           | uint8_t
>= 253 && <= 0xffff                      | 3           | 0xfd followed by the number as uint16_t
>= 0x10000 && <= 0xffffffff              | 5           | 0xfe followed by the number as uint32_t
>= 0x100000000 && <= 0xffffffffffffffff  | 9           | 0xff followed by the number as uint64_t

For example, the number 515 is encoded as 0xfd0302.
"""
struct CompactSizeUInt <: Unsigned
    value::Unsigned
    prefix::Union{Nothing, UInt8}
end

CompactSizeUInt(n::Integer) =
    n <  0x00               ? error("Integer is negative!") :
    n <= 0xfc               ? CompactSizeUInt(UInt8(n), nothing) :
    n <= 0xffff             ? CompactSizeUInt(UInt16(n), 0xfd) :
    n <= 0xffffffff         ? CompactSizeUInt(UInt32(n), 0xfe) :
    n <= 0xffffffffffffffff ? CompactSizeUInt(UInt64(n), 0xff) :
    error("Integer is too large!")

function Base.show(io::IO, z::CompactSizeUInt)
    print(io, Int(z.value))
end

String(z::CompactSizeUInt) = string(Int(z.value))

"""
    read(io::IOBuffer)::CompactSizeUInt

Returns a CompactSizeUInt from an IO stream
"""
function CompactSizeUInt(io::IOBuffer)
    p = read(io, 1)[1]
    if p == 0xfd
        n = ltoh(reinterpret(UInt16, read(io, 2))[1])
    elseif p == 0xfe
        n = ltoh(reinterpret(UInt32, read(io, 4))[1])
    elseif p == 0xff
        n = ltoh(reinterpret(UInt64, read(io, 8))[1])
    else
        n = p
        p = nothing
    end
    CompactSizeUInt(n, p)
end

"""
    serialize(n::CompactSizeUInt) -> Vector{UInt8}

Returns the bytes serialization of a CompactSizeUInt
"""
function serialize(n::CompactSizeUInt)
    if n.prefix == nothing
        return [n.value]
    else
        return append!([n.prefix], reinterpret(UInt8, [htol(n.value)]))
    end
end
