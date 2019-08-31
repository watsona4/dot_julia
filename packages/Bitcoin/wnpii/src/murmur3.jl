module Murmur3

export hash32

@inline function rotl32(var::Integer, value::Integer)
    (var << value) | ((var & 0xffffffff) >> (32-value))
end

@inline function fmix32(value::Integer)
    value ⊻= ((value & 0xffffffff) >> 16)
    value *= 0x85ebca6b
    value ⊻= ((value & 0xffffffff) >> 13)
    value *= 0xc2b2ae35
    value ⊻= ((value & 0xffffffff) >> 16)
end

function hash32(data::Vector{UInt8}, seed::UInt32=zero(UInt32))
    c1 = 0xcc9e2d51
    c2 = 0x1b873593
    h = seed

    len = length(data)
    blocks = div(len, 4)
    p = convert(Ptr{UInt32}, pointer(data))

    # Body
    for next_block ∈ 1:blocks
        k = big(unsafe_load(p, next_block))
        k *= c1
        k = rotl32(k, 15)
        k *= c2

        h ⊻= k
        h = rotl32(h, 13)
        h = h * 5 + 0xe6546b64
    end

    # Tail
    k = zero(BigInt)
    remainder = len & 3
    last_ = blocks * 4
    if remainder == 3
        k |= (UInt32(data[last_ + 3]) & 0xff) << 16
    end
    if remainder ∈ 2:3
        k |= (UInt32(data[last_ + 2]) & 0xff) << 8
    end
    if remainder ∈ 1:3
        k |= UInt32(data[last_ + 1]) & 0xff
        k *= c1
        k = rotl32(k, 15)
        k *= c2
        h ⊻= k
    end

    # Finalization
    h ⊻= len
    h = fmix32(h)

    h & 0xffffffff

end

hash32(data::Vector{UInt8}, seed::Int) = hash32(data, UInt32(seed))
hash32(data::AbstractString, seed::UInt32) = hash32(UInt8.(collect(data)), seed)
hash32(data::AbstractString, seed::Int) = hash32(UInt8.(collect(data)), UInt32(seed))
hash32(data::AbstractString) = hash32(UInt8.(collect(data)), UInt32(0))

end
