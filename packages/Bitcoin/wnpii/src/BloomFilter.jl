BIP37_CONSTANT = 0xfba4c795

struct BloomFilter
    size::Unsigned
    bit_field::Vector{Bool}
    function_count::UInt32
    tweak::UInt32
    BloomFilter(size::Integer, function_count::Integer, tweak::Integer) = new(size, fill(false, size * 8), function_count, tweak)
end

"""
Add an item to the filter
"""
function add!(bf::BloomFilter, item)
    for i in 1:bf.function_count
        seed = (i-1) * BIP37_CONSTANT + bf.tweak
        h = Murmur3.hash32(item, seed%UInt32)
        bit = mod(h, (bf.size * 8)) + 1
        bf.bit_field[bit] = 1
    end
end


"""
Returns an Vector{UInt8} representing the flagbits.
"""
function filter_bytes(bf::BloomFilter)
    flags2bytes(bf.bit_field)
end
