# Copyright (c) 2019 Guido Kraemer
# Copyright (c) 2019 Simon Castano
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.

"""
    TxOut

Each output spends a certain number of satoshis, placing them under control of
anyone who can satisfy the provided pubkey script.
A `TxOut` is composed of
- `value::UInt64`, number of satoshis to spend. May be zero; the sum of all
outputs may not exceed the sum of satoshis previously spent to the outpoints
provided in the input section. (Exception: coinbase transactions spend the
block subsidy and collected transaction fees.)
- `scriptpubkey::Script` which defines the conditions which must be
satisfied to spend this output.

"""
struct TxOut
    value           :: UInt64
    scriptpubkey    :: Script
end

"""
    TxOut(io::IOBuffer)

Parse an `IOBuffer` to a `TxOut`
"""
function TxOut(io::IOBuffer)
    value = read(io, UInt64)
    scriptpubkey = Script(io)

    TxOut(value, scriptpubkey)
end

function Base.show(io::IO, output::TxOut)
    println(io, "Transaction output: ₿" * string(output.value/100000000))
    println(io, "ScriptPubKey:")
    println(io, output.scriptpubkey)
end

"""
    serialize(tx::TxOut) -> Vector{UInt8}

Returns the byte serialization of the transaction output
"""
function serialize(tx::TxOut)
    result = bytes(tx.value, len=8, little_endian=true)
    append!(result, serialize(tx.scriptpubkey))
    return result
end
