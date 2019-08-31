# BitcoinPrimitives.jl Documentation

Bitcoin block and transaction data type for Julia

## Base Types

```@docs
CompactSizeUInt
Outpoint
TxIn
TxOut
Tx
Block
Header
Script
Witness
```

## Parse Functions

```@docs
CompactSizeUInt(io::IOBuffer)
Outpoint(io::IOBuffer)
Script(io::IOBuffer)
script
Witness(io::IOBuffer)
TxIn(io::IOBuffer)
TxOut(io::IOBuffer)
Tx(io::IOBuffer)
Block(io::IOBuffer)
Header(io::IOBuffer)
```

## Serialize Functions

```@docs
serialize(n::CompactSizeUInt)
serialize(prevout::Outpoint)
serialize(::Script)
serialize(::Witness)
serialize(::TxIn)
serialize(::TxOut)
serialize(::Tx)
serialize(::Block)
```

## Transaction Functions

```@docs
iscoinbase
coinbase_height
```

## Script Functions

```@docs
script(bin::Vector{UInt8}; type::Symbol)
type(script::Script)
```

## Cryptographic Functions

```@docs
hash256
```

## Buy me a cup of coffee

[Donate Bitcoin](bitcoin:34nvxratCQcQgtbwxMJfkmmxwrxtShTn67)

## Index

```@index
```
