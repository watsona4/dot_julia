# LogProbs

[![Build Status](https://travis-ci.org/dharasim/LogProbs.jl.svg?branch=master)](https://travis-ci.org/dharasim/LogProbs.jl)
[![Coverage Status](https://coveralls.io/repos/dharasim/LogProbs.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/dharasim/LogProbs.jl?branch=master)
[![codecov.io](http://codecov.io/github/dharasim/LogProbs.jl/coverage.svg?branch=master)](http://codecov.io/github/dharasim/LogProbs.jl?branch=master)

This package provides the Type `LogProb` for calculations with [logspace probabilities](https://en.wikipedia.org/wiki/Log_probability).

## Usage
```julia
julia> using LogProbs

julia> p = LogProb(0.2)
LogProb(0.2)

julia> q = LogProb(0.5)
LogProb(0.5)

julia> p + q
LogProb(0.7)

julia> float(p + q)
0.7

julia> log(p + q)
-0.35667494393873234

julia> float(p * q)
0.10000000000000002

julia> q - p
LogProb(0.30000000000000004)

julia> q - p == LogProb(0.3)
false

julia> q - p ≈ LogProb(0.3)
true

julia> q / p
LogProb(2.5)

julia> p / q
LogProb(0.4)

julia> rand(LogProb)
LogProb(0.8973798055014042)

julia> p < q, q < p
(true, false)

julia> information(p) # Shannon information content in bits
2.321928094887362
```
