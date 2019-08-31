# Copyright (c) 2019 Guido Kraemer
# Copyright (c) 2019 Simon Castano
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

# struct Header
#     version           ::UInt32
#     previous_hash     ::UInt256 #Vector{UInt8} # length 32
#     merkle_root       ::UInt256 #Vector{UInt8} # length 32
#     timestamp         ::UInt32
#     difficulty_target ::UInt32
#     nonce            ::UInt32
# end
#
# The following implementation hopefully is
# more efficient, because no conversions at reading time have to be made:

"""
    Header

Data Structure representing the Header of a Block in the Bitcoin blockchain.

Data are store as an `NTuple{80, UInt8}` without parsinf per se.
The elements of the `Header` can be accessed by `header.element`.

```julia
header.version
header.prevhash
header.merkleroot
header.time
header.bits
header.nonce
```
"""
struct Header
    data :: Vector{UInt8}
end

"""
    Header(x::IO) -> Header

Parse `Header` from an `IO`
"""
Header(io::IO) = Header(read(io, 80))

@inline Base.getindex(x::Header, r) = x.data[r]

@inline function Base.getproperty(x::Header, d::Symbol)
    if     d == :version    ltoh(reinterpret(UInt32, x.data[1:4])[1])
    elseif d == :prevhash   x.data[5:36]
    elseif d == :merkleroot x.data[37:68]
    elseif d == :time       ltoh(reinterpret(UInt32, x.data[69:72])[1])
    elseif d == :bits       ltoh(reinterpret(UInt32, x.data[73:76])[1])
    elseif d == :nonce      ltoh(reinterpret(UInt32, x.data[77:80])[1])
    else getfield(x, d)
    end
end

function Base.propertynames(::Type{Header}, private = false)
    (:version, :prevhash, :merkleroot, :time, :bits, :nonce,
     fieldnames(Header)...)
end

function Base.show(io::IO, header::Header)
    println(io, "  Version:    " * string(header.version,    base = 16))
    println(io, "  Prev Hash:  " * bytes2hex(header.prevhash))
    println(io, "  Root:       " * bytes2hex(header.merkleroot))
    println(io, "  Time:       " * string(header.time,       base = 10))
    println(io, "  Difficulty: " * string(header.bits,       base = 16))
    println(io, "  Nonce:      " * string(header.nonce,      base = 10))
end

"""
    serialize(header::Header) -> Vector{UInt8}

Returns the 80 byte Vector{UInt8} for the block header
"""
function serialize(header::Header)
    result = Vector(reinterpret(UInt8, [htol(header.version)]))
    append!(result, header.prevhash)
    append!(result, header.merkleroot)
    append!(result, Vector(reinterpret(UInt8, [htol(header.time)])))
    append!(result, Vector(reinterpret(UInt8, [htol(header.bits)])))
    append!(result, Vector(reinterpret(UInt8, [htol(header.nonce)])))
end

"""
    bip9(header::Header) -> Bool

Returns whether this header is signaling readiness for BIP9

    BIP9 is signalled if the top 3 bits are 001
    remember version is 32 bytes so right shift 29 (>> 29) and see if
    that is 001
"""
bip9(header::Header) = header.version >> 29 == 0b001

"""
    bip91(header::Header) -> Bool

Returns whether this header is signaling readiness for BIP91

    BIP91 is signalled if the 5th bit from the right is 1
    shift 4 bits to the right and see if the last bit is 1
"""
bip91(header::Header) = header.version >> 4 & 1 == 1

"""
    bip141(header::Header) - > Bool

Returns whether this header is signaling readiness for BIP141

    BIP91 is signalled if the 2nd bit from the right is 1
    shift 1 bit to the right and see if the last bit is 1
"""
bip141(header::Header) = header.version >> 1 & 1 == 1

"""
    target(header::Header) -> BigInt

Returns the proof-of-work target based on the bits

    last byte is exponent
    the first three bytes are the coefficient in little endian
    the formula is: coefficient * 256**(exponent-3)
"""
function target(header::Header)
    exponent = header.bits >> 24
    coefficient = header.bits & 0x00ffffff
    return coefficient * big(256)^(exponent - 3)
end

"""
    difficulty(header::Header) -> BigInt

Returns the header difficulty based on the bits

    difficulty is (target of lowest difficulty) / (header's target)
    lowest difficulty has bits that equal 0xffff001d
"""
function difficulty(header::Header)
    lowest = 0xffff * big(256)^(0x1d - 3)
    return div(lowest, target(header))
end

"""
    check_pow(header::Header) -> Bool

Returns whether this header satisfies proof of work

    get the hash256 of the serialization of this header
    interpret this hash as a little-endian number
    return whether this integer is less than the target
"""
function check_pow(header::Header)
    block_hash = hash256(header)
    proof = to_int(block_hash, little_endian=true)
    return proof < target(header)
end
