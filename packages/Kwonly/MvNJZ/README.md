# Kwonly.jl --- Macro to generate keyword-only version of a function

[![Build Status][travis-img]][travis-url]
[![Coverage Status][coveralls-img]][coveralls-url]
[![codecov.io][codecov-img]][codecov-url]


## Basic Usage

Kwonly.jl provides a macro `@add_kwonly`.  It creates a keyword-only
version of the given function.  Example:

```julia
using Kwonly

struct A
    x
    y
    @add_kwonly A(x, y=2) = new(x, y)
end
```

This macro add a keyword-only constructor by expanding `A(x, y=2) =
new(x, y)` into:

  ```julia
  A(x, y) = new(x, y)                                      # original
  A(; x = throw(UndefKeywordError(:x)), y=2) = new(x, y)   # keyword-only
  ```

So, the struct `A` can also be constructed by using only keyword
arguments:

```julia
@test A(1) == A(x=1)
```


[travis-img]: https://travis-ci.org/tkf/Kwonly.jl.svg?branch=master
[travis-url]: https://travis-ci.org/tkf/Kwonly.jl
[coveralls-img]: https://coveralls.io/repos/tkf/Kwonly.jl/badge.svg?branch=master&service=github
[coveralls-url]: https://coveralls.io/github/tkf/Kwonly.jl?branch=master
[codecov-img]: http://codecov.io/github/tkf/Kwonly.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/tkf/Kwonly.jl?branch=master
