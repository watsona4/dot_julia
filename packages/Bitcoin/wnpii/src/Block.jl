import Base.hash

abstract type AbstractBlock end

struct BlockHeader <: AbstractBlock
    version::UInt32
    prev_block::Vector{UInt8}
    merkle_root::Vector{UInt8}
    timestamp::UInt32
    bits::UInt32
    nonce::UInt32
    BlockHeader(version, prev_block, merkle_root, timestamp, bits, nonce) = new(version, prev_block, merkle_root, timestamp, bits, nonce)
end

function show(io::IO, z::BlockHeader)
    print(io, "Block\n--------\nVersion : ", z.version,
            "\nPrevious Block : ", bytes2hex(z.prev_block),
            "\nMerkle Root : ", bytes2hex(z.merkle_root),
            "\nTime Stamp : ", unix2datetime(z.timestamp),
            "\nBits : ", z.bits,
            "\nNonce : ", z.nonce)
end

"""
Takes a byte stream and parses a block. Returns a Block object
"""
function io2blockheader(s::IOBuffer)
    version = ltoh(reinterpret(UInt32, read(s, 4))[1])
    prev_block = read(s, 32)
    merkle_root = read(s, 32)
    timestamp = ltoh(reinterpret(UInt32, read(s, 4))[1])
    bits = ltoh(reinterpret(UInt32, read(s, 4))[1])
    nonce = ltoh(reinterpret(UInt32, read(s, 4))[1])
    return BlockHeader(version, prev_block, merkle_root, timestamp, bits, nonce)
end

"""
Returns the 80 byte block header
"""
function serialize(block::BlockHeader)
    result = Vector(reinterpret(UInt8, [htol(block.version)]))
    prev_block = copy(block.prev_block)
    append!(result, prev_block)
    append!(result, block.merkle_root)
    append!(result, Vector(reinterpret(UInt8, [htol(block.timestamp)])))
    append!(result, Vector(reinterpret(UInt8, [htol(block.bits)])))
    append!(result, Vector(reinterpret(UInt8, [htol(block.nonce)])))
end

"""
Returns the hash256 interpreted little endian of the block
"""
function hash(block::BlockHeader)
    s = serialize(block)
    h256 = hash256(s)
    return reverse!(h256)
end

"""
Human-readable hexadecimal of the block hash
"""
function id(block::BlockHeader)
    return bytes2hex(hash(block))
end

"""
Returns whether this block is signaling readiness for BIP9

    BIP9 is signalled if the top 3 bits are 001
    remember version is 32 bytes so right shift 29 (>> 29) and see if
    that is 001
"""
function bip9(block::BlockHeader)
    return block.version >> 29 == 0b001
end

"""
Returns whether this block is signaling readiness for BIP91

    BIP91 is signalled if the 5th bit from the right is 1
    shift 4 bits to the right and see if the last bit is 1
"""
function bip91(block::BlockHeader)
    return block.version >> 4 & 1 == 1
end

"""
Returns whether this block is signaling readiness for BIP141

    BIP91 is signalled if the 2nd bit from the right is 1
    shift 1 bit to the right and see if the last bit is 1
"""
function bip141(block::BlockHeader)
    return block.version >> 1 & 1 == 1
end

"""
Returns the proof-of-work target based on the bits

    last byte is exponent
    the first three bytes are the coefficient in little endian
    the formula is: coefficient * 256**(exponent-3)
"""
function target(block::BlockHeader)
    exponent = block.bits >> 24
    coefficient = block.bits & 0x00ffffff
    return coefficient * big(256)^(exponent - 3)
end

"""
Returns the block difficulty based on the bits

    difficulty is (target of lowest difficulty) / (block's target)
    lowest difficulty has bits that equal 0xffff001d
"""
function difficulty(block::BlockHeader)
    lowest = 0xffff * big(256)^(0x1d - 3)
    return div(lowest, target(block))
end

"""
Returns whether this block satisfies proof of work

    get the hash256 of the serialization of this block
    interpret this hash as a little-endian number
    return whether this integer is less than the target
"""
function check_pow(block::BlockHeader)
    block_hash = hash(block)
    proof = to_int(block_hash, little_endian=true)
    return proof < target(block)
end

"""
    validate_merkle_root(block::BlockHeader, hashes::Vector{Vector{UInt8}})
    -> Bool

Gets the merkle root of the hashes and checks that it's
the same as the merkle root of this block header.
"""
function validate_merkle_root(block::BlockHeader, hashes::Vector{Vector{UInt8}})
    hashes = [reverse!(copy(h)) for h in hashes]
    root = merkle_root(hashes)
    merkle_root(hashes) == block.merkle_root
end

struct Block <: AbstractBlock
    magic::UInt32
    size::UInt32
    header::BlockHeader
    tx_counter
    tx::Vector{UInt8}
end

# TODO Add Block serialization function
