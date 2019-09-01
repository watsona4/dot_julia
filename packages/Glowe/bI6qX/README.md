# Glowe

Julia interface to [GloVe](https://nlp.stanford.edu/projects/glove/).

[![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](LICENSE.md)
[![Build Status](https://travis-ci.org/zgornel/Glowe.jl.svg?branch=master)](https://travis-ci.org/zgornel/Glowe.jl)
[![Coverage Status](https://coveralls.io/repos/github/zgornel/Glowe.jl/badge.svg?branch=master)](https://coveralls.io/github/zgornel/Glowe.jl?branch=master)

This package provides functionality for generating and working with GloVe word embeddings. The training is done using the original C code from the [GloVe github repository](https://github.com/stanfordnlp/GloVe).

Note that there is also a package called [Glove.jl](https://github.com/domluna/Glove.jl) that provides a pure Julia implementation of the algorithm.

* [Release Notes](https://github.com/zgornel/Glowe.jl/blob/master/NEWS.md)


## Installation

```julia
Pkg.clone("https://github.com/zgornel/Glowe.jl")
```
for the latest `master` or
```julia
Pkg.add("Glowe")
```
for the stable versions.


## Documentation

Most of the documentation is provided in Julia's native docsystem.


## Examples

Following Word2Vec.jl's example, considering the corpus from http://mattmahoney.net/dc/text8.zip extracted as text file ``text8`` in the current working directory, the GloVe model can be obtained with:

```julia
julia> # Training (may take a while)
       vocab_count("text8", "vocab.txt", min_count=5, verbose=1);
       cooccur("text8", "vocab.txt", "cooccurrence.bin", memory=8.0, verbose=1);
       shuffle("cooccurrence.bin", "cooccurrence.shuf.bin", memory=8.0, verbose=1);
       glove("cooccurrence.shuf.bin", "vocab.txt", "text8-vec", threads=8,
             x_max=10.0, iter=15, vector_size=300, binary=0, write_header=1,
             verbose=1);
# BUILDING VOCABULARY
# Truncating vocabulary at min count 5.
# Using vocabulary of size 71290.
#
# COUNTING COOCCURRENCES
# window size: 15
# context: symmetric
# Merging cooccurrence files: processed 60666468 lines.
#
# SHUFFLING COOCCURRENCES
# array size: 510027366
# Merging temp files: processed 60666468 lines.
#
# TRAINING MODEL
# Read 60666468 lines.
# vector size: 300
# vocab size: 71290
# x_max: 10.000000
# alpha: 0.750000
# 12/11/18 - 12:58.58AM, iter: 001, cost: 0.070201
# 12/11/18 - 01:00.33AM, iter: 002, cost: 0.052521
# ...
```

The model can be imported with
```julia
model = wordvectors("text8-vec.txt", Float32, header=true, kind=:text)
# WordVectors 71291 words, 300-element Float32 vectors
```

The vector representation of a word can be obtained using ``get_vector``.
```julia
julia> get_vector(model, "book")
# 300-element Array{Float32,1}:
#   0.006189716
#   0.04822071
#   0.017121462
#   ...
```

The cosine similarity of ``book``, for example, can be computed using ``cosine_similar_words``.
```julia
julia> cosine_similar_words(model, "book")
# 10-element Array{String,1}:
#  "book"
#  "books"
#  "published"
#  "domesday"
#  "novel"
#  "comic"
#  "written"
#  "bible"
#  "urantia"
#  "work"
```

Word vectors have many interesting properties. For example,
``vector("king") - vector("man") + vector("woman")`` is close to ``vector("queen")``.

```julia
julia> analogy_words(model, ["king", "woman"], ["man"])
# 5-element Array{String,1}:
#  "queen"
#  "daughter"
#  "children"
#  "wife"
#  "son"
```


## License

This code has an MIT license and therefore it is free.
GloVe is released under an Apache License v2.0.


## References

[1] [GloVe: Global Vectors for Word Representation](https://nlp.stanford.edu/projects/glove/)

[2] [Glove.jl - native Julia implementation](https://github.com/domluna/Glove.jl)


## Acknowledgements

The design of the package relies on design concepts from [the word2vec Julia interface, Word2Vec.jl](https://github.com/zgornel/Word2Vec.jl).


## Reporting Bugs

Please [file an issue](https://github.com/zgornel/Glowe.jl/issues/new) to report a bug or request a feature.
