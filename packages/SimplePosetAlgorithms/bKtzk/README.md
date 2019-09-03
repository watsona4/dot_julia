# SimplePosetAlgorithms


[![Build Status](https://travis-ci.org/scheinerman/SimplePosetAlgorithms.jl.svg?branch=master)](https://travis-ci.org/scheinerman/SimplePosetAlgorithms.jl)


[![codecov.io](http://codecov.io/github/scheinerman/SimplePosetAlgorithms.jl/coverage.svg?branch=master)](http://codecov.io/github/scheinerman/SimplePosetAlgorithms.jl?branch=master)


Additional algorithms for the `SimplePoset` type. Relies on
`SimpleGraphAlgorithms`. See that module for more information.

**Note**: Calculations are done via an integer linear program and
  there can be quite slow.

## Functions

* `max_chain(P)` returns a maximum size chain of the `SimplePoset`.

* `max_antichain(P)` returns a maximum size antichain of the
`SimplePoset`

* `width(P)` returns the size of a largest antichain in the
  `SimplePoset`. [**Note**: The function `height` (which gives the size
  of a largest chain) is already defined in the `SimplePosets` module
  and does not rely on integer linear programming.]

* `realizer(P,d)` returns a realizer of `P` with `d` linear extensions,
or throws an error if none exists. This is returned as a matrix with
`d` columns.

* `realize_poset(R)` creates a poset from a realizer. Here `R` is a
matrix whose columns are the linear orders of the realizer.

* `dimension(P)` returns the minimum size of a realizer. Use
`dimension(P,true)` for verbose reporting.

## Examples

```julia
julia> P = BooleanLattice(5)
SimplePoset{String} (32 elements)

julia> max_chain(P)
{00000,00001,01001,11001,11011,11111}

julia> max_antichain(P)
{00111,01011,01101,01110,10011,10101,10110,11001,11010,11100}

julia> P = Divisors(30)
SimplePoset{Int64} (8 elements)

julia> realizer(P,3)
8×3 Array{Int64,2}:
  1   1   1
  3   2   3
  5   5   2
 15  10   6
  2   3   5
 10  15  15
  6   6  10
 30  30  30

julia> realize_poset(ans) == P
true

julia> P = BooleanLattice(4)
SimplePoset{String} (16 elements)

julia> dimension(P,true)
2 <= dim(P) <= 8	looking for a 5 realizer	confirmed
2 <= dim(P) <= 5	looking for a 3 realizer	none exists
4 <= dim(P) <= 5	looking for a 4 realizer	confirmed
4 <= dim(P) <= 4	and we're done
4
```
