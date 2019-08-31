# Copyright (c) 2019 Guido Kraemer
# Copyright (c) 2019 Simon Castano
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

"""
    Witness

Witness data type has a single `data` field, stored as `Vector{Vector{UInt8}}`
in which each inner `Vector{UInt8}` represent a stack item.

The `Witness` is a serialization of all witness data of the transaction.
Each `TxIn` is associated with a witness field. A witness field starts with a
`CompactSizeUInt` to indicate the number of stack items for the `TxIn`.
It is followed by stack items, with each item starts with a `CompactSizeUInt`
to indicate the length.
Witness data is NOT script.

A non-witness program `TxIn` MUST be associated with an empty witness field,
represented by a `0x00`. If all `TxIn`s are not witness program, a
transaction's `wtxid` is equal to its `txid`.
"""
struct Witness
    data :: Vector{Vector{UInt8}}
end

Witness() = Witness([[0x00]])

"""
    Witness(io::IO) -> Witness

Parse `Witness` from an IOBuffer
"""
function Witness(io::IO)
    n_items = CompactSizeUInt(io).value
    data = Vector{Vector{UInt8}}(undef, n_items)

    for i in 1:n_items
        l = CompactSizeUInt(io).value
        data[i] = read!(io, Array{UInt8, 1}(undef, l))
    end

    Witness(data)
end

function Base.show(io::IO, program::Witness)
    println("Witness Program:")
    for item in program.data
        println(io, bytes2hex(item))
    end
end

"""
    serialize(program::Witness) -> Vector{UInt8}

Serialize a `Witness` data type starting with a `CompactSizeUInt` to indicate
the number of stack items for the `TxIn`.
It is followed by stack items, with each item starts with a `CompactSizeUInt`
to indicate the length.
"""
function serialize(program::Witness)
    l = CompactSizeUInt(length(program.data))
    result = serialize(l)
    for item in program.data
        l = CompactSizeUInt(length(item))
        append!(result, serialize(l))
        append!(result, item)
    end
    return result
end
