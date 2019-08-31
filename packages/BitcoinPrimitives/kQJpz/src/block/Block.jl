# Copyright (c) 2019 Guido Kraemer
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

include("Header.jl")

"""
    Block

Data Structure representing a Block in the Bitcoin blockchain.

Consists of a `block.header::Header` and
`block.transactions::Vector{Tx}`.
"""
struct Block
    header              :: Header
    transactions        :: Vector{Tx}
end

"""
    Block(io::IOBuffer) -> Block

Parse a `Block` from an `IOBuffer`
"""
function Block(io::IOBuffer)
    blockheader = Header(io)
    n_trans = CompactSizeUInt(io).value
    @assert n_trans > zero(n_trans) "Block must have at least one transaction"
    transactions = [Tx(io) for i in 1:n_trans]

    return Block(blockheader, transactions)
end

function Base.show(io::IO, block::Block)
    print(io, block.header)
    for tx in block.transactions
        print(io, tx)
    end
end

"""
    serialize(block::Header) -> Vector{UInt8}

Serialize a Block
"""
function serialize(block::Block)
    result = serialize(block.header)
    append!(result, length(block.transactions))
    for tx in block.transactions
        append!(result, serialize(tx))
    end
    return result
end
