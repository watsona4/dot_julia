"""
    Outpoint

Because a single transaction can include multiple outputs,
the Outpoint structure includes both a TXID (or `txid`) and an output `index`
number to refer to specific output.
- `txid`, the TXID of the transaction holding the output to spend.
  The TXID is a hash provided here in internal byte order.
- `index`, the output index number of the specific output to spend from the transaction.
  The first output is 0x00000000.
"""
struct Outpoint
    txid    :: Vector{UInt8}
    index   :: UInt32
end

"""
    Outpoint(io::IOBuffer) -> Outpoint

Parse an `Outpoint` from an IOBuffer
"""
function Outpoint(io::IOBuffer)
    txid = reverse(read(io, 32))
    index = read(io, UInt32)
    Outpoint(txid, index)
end

function Base.show(io::IO, prevout::Outpoint)
    println(io, "Outpoint: " * bytes2hex(prevout.txid) * ":" * string(prevout.index, base=10))
end

"""
    serialize(prevout::Outpoint) -> Vector{UInt8}

Returns the byte serialization of the outpoint
"""
function serialize(prevout::Outpoint)
    result = copy(prevout.txid)
    reverse!(result)
    append!(result, bytes(prevout.index, len=4, little_endian=true))
    return result
end
