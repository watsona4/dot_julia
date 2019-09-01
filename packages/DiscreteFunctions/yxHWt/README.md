# DiscreteFunctions


[![Build Status](https://travis-ci.org/scheinerman/DiscreteFunctions.jl.svg?branch=master)](https://travis-ci.org/scheinerman/DiscreteFunctions.jl)


[![codecov.io](http://codecov.io/github/scheinerman/DiscreteFunctions.jl/coverage.svg?branch=master)](http://codecov.io/github/scheinerman/DiscreteFunctions.jl?branch=master)


This module defines the `DiscreteFunction` type which represents a
function defined on the set `{1,2,...,n}` (`n` must be positive).

## Basic Constructor

A `DiscreteFunction` is created by providing a list of values either by
passing an array of `Int` values or as a list of `Int` arguments:
```
julia> using DiscreteFunctions

julia> f = DiscreteFunction([2,3,1,4]);

julia> g = DiscreteFunction(2,3,1,4);

julia> f==g
true
```
Function evaluation may use either `f(x)` or `f[x]`. It is possible
to change the value of `f` at `x` using the latter.

If `p` is a `Permutation` then `DiscreteFunction(p)` creates a
`DiscreteFunction` based on `p`.
```
julia> using Permutations

julia> p = RandomPermutation(6)
(1,6)(2,5,3,4)

julia> DiscreteFunction(p)
DiscreteFunction on [6]
   1   2   3   4   5   6
   6   5   4   2   3   1
```

## Special Constructors

* `IdentityFunction(n)` creates the identity function on the set `{1,2,...,n}`.
* `RandomFunction(n)` creates a random function on the set `{1,2,...,n}`.


## Operations and Methods


The composition of functions `f` and `g` is computed with `f*g`.
Exponentiation signals repeated composition,
i.e., `f^4` is the same as `f*f*f*f`.

We can test if `f` is invertible using `has_inv(f)` and `inv(f)` returns the
inverse function (or throws an error if no inverse exists). This can also
be computed as `f^-1` and, in general, if `f` is invertible it can be raised
to negative exponents. The function `is_permutation` is a synonym for `has_inv`.

#### Other methods

+ `length(f)` returns the number of elements in `f`'s domain.  
+ `fixed_points(f)` returns a list of the fixed points in the function.
+ `image(f)` returns a `Set` containing the output values of `f`.


#### Expensive operations
+ `all_functions(n)` returns an iterator for all functions defined on `1:n`.
Note that there are `n^n` such functions so this grows quickly.
+ `sqrt(f)` returns a `DiscreteFunction` `g` such that `g*g==f` or throws an
error if no such function exists. (Currently this is done by iterating over all
possible functions; that's very bad.)

## Extras

This is some additional code that is not automatically loaded by `using DiscreteFunctions`.
Use `include` on the appropriate file in the `src` directory.

### `src/tree_function.jl`

This file defines `tree2function(G::SimpleGraph)`. It assumes that `G` is a
tree with vertex set `1:n` and returns a `DiscreteFunction` defined by
pointing all edges to the root, `1`.

### `src/draw_function.jl`

This file defines `draw(f)` to give a picture of `f`.
