# SimpleIntegrals


[![Build Status](https://travis-ci.org/jw3126/SimpleIntegrals.jl.svg?branch=master)](https://travis-ci.org/jw3126/SimpleIntegrals.jl)
[![codecov.io](https://codecov.io/github/jw3126/SimpleIntegrals.jl/coverage.svg?branch=master)](http://codecov.io/github/jw3126/SimpleIntegrals.jl?branch=master)

# Usage
```julia
using SimpleIntegrals
xs = sort!(randn(100))
ys = randn(100)
integral(xs, ys)
```
