# Copyright (c) 2019 Guido Kraemer
# Copyright (c) 2019 Simon Castano
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

"""
    TxIn

Each non-coinbase input spends an outpoint from a previous transaction.
A `TxIn` is composed of
- `prevout::Outpoint`, The previous outpoint being spent
- `scriptsig::Vector{UInt8}`, which satisfies the conditions placed in
the outpoint’s pubkey script. Should only contain data pushes
- `sequence::UInt32` number. Default for Bitcoin Core and almost all other
programs is `0xffffffff`
"""
struct TxIn
    prevout     :: Outpoint
    scriptsig   :: Script
    sequence    :: UInt32
end

"""
    TxIn(io::IOBuffer) -> TxIn

Parse an `IOBuffer` to a `TxIn`
"""
function TxIn(io::IOBuffer)
    prevout = Outpoint(io)
    scriptsig = Script(io)
    sequence = read(io, UInt32)

    TxIn(prevout, scriptsig, sequence)
end

function Base.show(io::IO, input::TxIn)
    println(io, "Transaction input (sequence: " * string(input.sequence, base=10) * "):")
    println(io, input.prevout)
    println(io, "ScriptSig:")
    println(io, input.scriptsig)
end

# function Base.showall(io::IO, input::TxIn)
#     println(io, "Transaction input:")
#     println(io, "  Hash:                  " * input.hash)
#     println(io, "  Output index:          " * input.output_index)
#     println(io, "  Unlocking script size: " * input.unlocking_script_size)
#     println(io, "  Unlocking script:      " * hexarray(input.unlocking_script))
#     println(io, "  Input Sequence:        " * input.sequence_number)
# end

"""
    serialize(tx::TxIn) -> Vector{UInt8}

Returns the byte serialization of the transaction input
"""
function serialize(tx::TxIn)
    result = serialize(tx.prevout)
    append!(result, serialize(tx.scriptsig))
    append!(result, bytes(tx.sequence, len=4, little_endian=true))
    return result
end
