# ShowSet


[![Build Status](https://travis-ci.org/scheinerman/ShowSet.jl.svg?branch=master)](https://travis-ci.org/scheinerman/ShowSet.jl)

[![Coverage Status](https://coveralls.io/repos/scheinerman/ShowSet.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/scheinerman/ShowSet.jl?branch=master)

[![codecov.io](http://codecov.io/github/scheinerman/ShowSet.jl/coverage.svg?branch=master)](http://codecov.io/github/scheinerman/ShowSet.jl?branch=master)

This module makes the printing of `Set` objects in Julia
nicer.

## Usage

Without the use of this module, `Set` objects display like this:

```julia
julia> BitSet([1,3,0])
BitSet([1,3,0])

julia> Set(["One", "Two", "Three"])
Set("One","Two","Three")
```

However, after `using ShowSet` it looks like this:
```julia
julia> BitSet([1,3,0])
{0,1,3}

julia> Set(["One", "Two", "Three"])
{One,Three,Two}
```

The elements of the `Set` object are sorted into ascending order
unless Julia is unable to do so. In that case, the order of the
objects is arbitrary.

```julia
julia> Set([1, "hello", 4.5, 2+3im])
{hello,2 + 3im,4.5,1}
```

## Conversion to `string`


We extend the `string` function for `Set` and `BitSet` objects to
provide for their conversion into `String` objects. Some examples:

```julia
julia> A = Set(["alpha", "beta", "gamma"]);

julia> string(A)
"{alpha,beta,gamma}"

julia> B = BitSet([5,3,1]);

julia> string(B)
"{1,3,5}"

julia> typeof(ans)
String
```
