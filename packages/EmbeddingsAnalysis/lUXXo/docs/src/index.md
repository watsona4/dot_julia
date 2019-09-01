```@meta
CurrentModule=EmbeddingsAnalysis
```

# Introduction

EmbeddingsAnalysis is a package for processing embeddings. At this point, only word embeddings are _de facto_ supported however other types (i.e. graph embeddings) could be used as well.

## Processing methods
The package implements the following embeddings processing algorithms:
  - [Artetxe et al. "Uncovering divergent linguistic information in word embeddings with lessons for intrinsic and extrinsic evaluation", 2018](https://arxiv.org/pdf/1809.02094.pdf)
  - [Vikas Raunak "Simple and effective dimensionality reduction for word embeddings", NIPS 2017 Workshop](https://arxiv.org/abs/1708.03629)
and utilities:
  - word vector compression through `CompressedWordVectors` (uses [QuantizedArrays.jl](https://github.com/zgornel/QuantizedArrays.jl))
  - saving `WordVectors`, `CompressedWordVectors` objects to disk in either binary or text format
  - convert `ConceptNet` objects to `WordVectors` objects

## Installation

Installation can be performed from either outside or inside Julia with:
```
$ git clone https://github.com/zgornel/EmbeddingsAnalysis.jl
```
and
```
using Pkg
Pkg.clone("https://github.com/zgornel/EmbeddingsAnalysis.jl")
```
respectively.
