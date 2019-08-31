# Copyright (c) 2019 Guido Kraemer
# Copyright (c) 2019 Simon Castano
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

include("../script/Script.jl")
include("../script/Witness.jl")
include("Outpoint.jl")
include("TxIn.jl")
include("TxOut.jl")


abstract type Transaction end

"""
Bitcoin transactions are broadcast between peers in a serialized byte format,
called raw format. It is this form of a transaction which is SHA256(SHA256())
hashed to create the TXID and, ultimately, the merkle root of a block
containing the transaction—making the transaction format part of the consensus
rules.

A raw transaction has the following top-level format:

- Transaction version number; currently version 1 or 2. Programs creating
transactions using newer consensus rules may use higher version numbers.
Version 2 means that BIP 68 applies.
- A marker which MUST be a 1-byte zero value: `0x00` (BIP 141)
- A flag which MUST be a 1-byte non-zero value: `0x01` (BIP 141)
- Transaction inputs
- Transaction outputs
- A time (Unix epoch time) or block number (BIP 68)

A transaction may have multiple inputs and outputs, so the `TxIn` and `TxOut`
structures may recur within a transaction.
"""
struct Tx <: Transaction
    version     :: UInt32
    marker      :: UInt8
    flag        :: UInt8
    inputs      :: Vector{TxIn}
    outputs     :: Vector{TxOut}
    witnesses   :: Vector{Witness}
    locktime    :: UInt32
end


"""
    Tx(io::IOBuffer) -> Tx

Parse an `IOBuffer` to a `Tx`
"""
function Tx(io::IOBuffer)

    version         =   ltoh(read(io, UInt32))

    x               =   CompactSizeUInt(io).value
    x == zero(x)    ?   segwit = true : segwit = false

    if segwit
        marker, flag    =   x, read(io, UInt8)
        @assert flag    ==  0x01
        txin_count      =   CompactSizeUInt(io).value
    else
        marker, flag    =   0xff, 0xff
        txin_count      =   x
    end

    inputs  = TxIn[TxIn(io)     for i ∈ 1:txin_count]
    outputs = TxOut[TxOut(io)   for i ∈ 1:CompactSizeUInt(io).value]

    if segwit
        witness_count = txin_count
        @assert witness_count > 0
        witnesses = Witness[Witness(io) for i ∈ 1:witness_count]
    else
        witnesses = [Witness()]
    end

    locktime = ltoh(read(io, UInt32))

    return Tx(version, marker, flag, inputs, outputs, witnesses, locktime)
end

function Base.show(io::IO, tx::Tx)
    println(io, "Transaction:      " * bytes2hex(reverse(hash256(tx))))
    println(io, "  Version:        " * string(tx.version,           base = 10))
    println(io, "  Marker:         " * string(tx.marker,            base = 10))
    println(io, "  Flag:           " * string(tx.flag,              base = 10))
    println(io, "  Input counter:  " * string(length(tx.inputs),    base = 10))
    println(io, "  Output counter: " * string(length(tx.outputs),   base = 10))
    println(io, "  Lock time:      " * string(tx.locktime,          base = 10))
end

"""
    serialize(tx::Tx) -> Vector{UInt8}

Returns the byte serialization of the transaction
"""
function serialize(tx::Tx)
    result = bytes(tx.version, len=4, little_endian=true)

    (tx.marker, tx.flag) == (0xff, 0xff) ? bip141 = false : bip141 = true
    bip141 ? append!(result, [tx.marker, tx.flag]) : nothing

    l = CompactSizeUInt(length(tx.inputs))
    append!(result, serialize(l))
    for input in tx.inputs
        append!(result, serialize(input))
    end

    l = CompactSizeUInt(length(tx.outputs))
    append!(result, serialize(l))
    for output in tx.outputs
        append!(result, serialize(output))
    end

    if bip141
        for i ∈ 1:length(tx.inputs)
            append!(result, serialize(tx.witnesses[i]))
        end
    end
    append!(result, bytes(tx.locktime, len=4, little_endian=true))
    return result
end

total_output(tx::Tx) = sum(x -> x.amount, tx.outputs)

"""
    iscoinbase(tx::Tx) -> Bool

Returns whether this transaction is a coinbase transaction or not
"""
function iscoinbase(tx::Tx)
    outpoint = tx.inputs[1].prevout
    length(tx.inputs) == 1 && outpoint.txid == fill(0x00, 32) && outpoint.index == 0xffffffff
end

"""
    coinbase_height(tx::Tx) ->

Returns the height of the block this coinbase transaction is in
Returns an `AssertionError` if `tx` isn't a coinbase transaction
"""
function coinbase_height(tx::Tx)
    @assert iscoinbase(tx) "This is not a coinbase transaction"
    height_bytes = tx.inputs[1].scriptsig.data[1]
    return to_int(height_bytes, little_endian=true)
end
