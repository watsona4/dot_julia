"""
    hash256(x::Block) -> Vector{UInt8}
    hash256(x::Header) -> Vector{UInt8}
    hash256(x::Tx) -> Vector{UInt8}

Hash a `Block`, `Header`, or `Tx`

```julia
hash256(block)
hash256(header)
hash256(transaction)
```
"""
hash256(x::Tx) = reverse(sha256(sha256(serialize(x))))
hash256(x::Header) = reverse(sha256(sha256(x.data)))
hash256(x::Block) = hash256(x.header)
