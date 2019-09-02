# LayerDicts

[![Build Status](https://travis-ci.org/invenia/LayerDicts.jl.svg?branch=master)](https://travis-ci.org/invenia/LayerDicts.jl)
[![CodeCov](https://codecov.io/gh/invenia/LayerDicts.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/invenia/LayerDicts.jl)

`LayerDict` is an `Associative` type that wraps a series of other associatives (e.g. `Dict`s).
When performing a lookup, a `LayerDict` will look through its associatives in the order they were passed to the constructor until it finds a match.
`LayerDict`s are immutable—you cannot call `setindex!` on them.
However, you can update its wrapped associatives and those changes will be reflected in future lookups.

## Example

```julia
using LayerDicts

dict1 = Dict{Symbol, Int}(:foo => 1, :bar => 1)
dict2 = Dict{Symbol, Int}()
dict3 = Dict{Symbol, Int}(:bar => 3, :baz => 3)

ld = LayerDict([dict1, dict2, dict3])
@assert ld[:foo] == 1
@assert ld[:bar] == 1
@assert ld[:baz] == 3
ld[:quuz]  # throws a KeyError
```
