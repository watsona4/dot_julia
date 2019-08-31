# Distributions

POMDPModelTools contains several utility distributions to be used in the POMDPs `transition` and `observation` functions. These implement the appropriate methods of the functions in the [distributions interface](http://juliapomdp.github.io/POMDPs.jl/latest/interfaces/#distributions).

This package also supplies [`showdistribution`](@ref) for pretty printing distributions as unicode bar graphs to the terminal.

## Sparse Categorical (`SparseCat`)

`SparseCat` is a sparse categorical distribution which is specified by simply providing a list of possible values (states or observations) and the probabilities corresponding to those particular objects.

Example: `SparseCat([1,2,3], [0.1,0.2,0.7])` is a categorical distribution that assignes probability 0.1 to `1`, 0.2 to `2`, 0.7 to `3`, and 0 to all other values.

```@docs
SparseCat
```

## Bool Distribution

```@docs
BoolDistribution
```

## Deterministic

```@docs
Deterministic
```

## Uniform

```@docs
Uniform
UnsafeUniform
```

## Pretty Printing
```@docs
showdistribution
```
