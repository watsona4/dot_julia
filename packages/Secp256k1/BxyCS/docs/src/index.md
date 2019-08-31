# Secp256k1.jl

Julia library for EC operations on curve secp256k1.

## Types

```@docs
Secp256k1.Point
Secp256k1.KeyPair
Secp256k1.Signature
```

## Functions

```@docs
Secp256k1.serialize(P::Secp256k1.Point; compressed::Bool)
Secp256k1.Point(io::IOBuffer)
Secp256k1.serialize(x::Signature)
Secp256k1.Signature(x::Vector{UInt8}; scheme::Symbol)
Secp256k1.ECDSA.sign
Secp256k1.ECDSA.verify
```

## Buy me a cup of coffee

[Donate Bitcoin](bitcoin:34nvxratCQcQgtbwxMJfkmmxwrxtShTn67)

## Index

```@index
```
