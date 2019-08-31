# BitcoinPrimitives.jl

[![pipeline status](https://gitlab.com/braneproject/BitcoinPrimitives.jl/badges/master/pipeline.svg)](https://gitlab.com/braneproject/BitcoinPrimitives.jl/commits/master)    [![coverage report](https://gitlab.com/braneproject/BitcoinPrimitives.jl/badges/master/coverage.svg)](https://gitlab.com/braneproject/BitcoinPrimitives.jl/commits/master)

## About

Provides Bitcoin block and transaction data type for Julia.
Based on Guido Kraemer work and his [BTCParser.jl](https://github.com/gdkrmr/BTCParser.jl)

## Usage

```julia
julia> raw_block = hex2bytes("0100000000000000000000000000000000000000000000000000000000000000000000003ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a29ab5f49ffff001d1dac2b7c0101000000010000000000000000000000000000000000000000000000000000000000000000ffffffff4d04ffff001d0104455468652054696d65732030332f4a616e2f32303039204368616e63656c6c6f72206f6e206272696e6b206f66207365636f6e64206261696c6f757420666f722062616e6b73ffffffff0100f2052a01000000434104678afdb0fe5548271967f1a67130b7105cd6a828e03909a67962e0ea1f61deb649f6bc3f4cef38c4f35504e51ec112de5c384df7ba0b8d578a4c702b6bf11d5fac00000000")
285-element Array{UInt8,1}:
 0x01
 0x00
 0x00
 0x00
    ⋮
 0x00
 0x00
 0x00

julia> block = Block(IOBuffer(raw_block))
  Version:    1
  Prev Hash:  0000000000000000000000000000000000000000000000000000000000000000
  Root:       3ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a
  Time:       1231006505
  Difficulty: 1d00ffff
  Nonce:      2083236893
Transaction:      5ebec6f270aba2f7d3002ccadfcffcc2c68cb13cd62c786118c6fefec9ac3de0
  Version:        1
  Marker:         255
  Flag:           255
  Input counter:  1
  Output counter: 1
  Lock time:      0


julia> block.transactions[1].inputs[1]
Transaction input (sequence: 4294967295):
Outpoint: 0000000000000000000000000000000000000000000000000000000000000000:4294967295

ScriptSig:
ffff001d
OP_CODE_4
5468652054696d65732030332f4a616e2f32303039204368616e63656c6c6f72206f6e206272696e6b206f66207365636f6e64206261696c6f757420666f722062616e6b73



julia> block.transactions[1].outputs[1]
Transaction output: ₿50.0
ScriptPubKey:
04678afdb0fe5548271967f1a67130b7105cd6a828e03909a67962e0ea1f61deb649f6bc3f4cef38c4f35504e51ec112de5c384df7ba0b8d578a4c702b6bf11d5f
OP_CHECKSIG
```

## Problems

- Please report any issues or improvement proposals
  [here](https://gitlab.com/braneproject/BitcoinPrimitives.jl/issues).

## Documentation

https://braneproject.gitlab.io/BitcoinPrimitives.jl/

## Buy me a cup of coffee

[Donate Bitcoin](bitcoin:34nvxratCQcQgtbwxMJfkmmxwrxtShTn67)
