# MerkleTrees.jl Documentation

MerkleTree implementation using double sha256 hash function.

## Functions

```@docs
MerkleTree(::Integer)
merkle_parent(::Vector{UInt8}, ::Vector{UInt8})
merkle_parent_level(hashes::Vector{Vector{UInt8}})
merkle_root(hashes::Vector{Vector{UInt8}})
root(tree::MerkleTree)
populate!(tree::MerkleTree, flag_bits::Vector{Bool}, hashes::Vector{Vector{UInt8}})
```

## Buy me a cup of coffee

[Donate Bitcoin](bitcoin:34nvxratCQcQgtbwxMJfkmmxwrxtShTn67)

## Index

```@index
```
