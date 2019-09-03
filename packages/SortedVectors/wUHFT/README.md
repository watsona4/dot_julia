# SortedVectors

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)<!--
![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) -->
[![Build Status](https://travis-ci.com/tpapp/SortedVectors.jl.svg?branch=master)](https://travis-ci.com/tpapp/SortedVectors.jl)
[![codecov.io](http://codecov.io/github/tpapp/SortedVectors.jl/coverage.svg?branch=master)](http://codecov.io/github/tpapp/SortedVectors.jl?branch=master)

A very lightweight Julia package to declare that a vector is sorted.

## Installation

The package is not (yet) registered. Install with

```julia
pkg> add https://github.com/tpapp/SortedVectors.jl
```

## How to use

### Standard constructor

The only exported symbol is `SortedVector`. Use

```julia
SortedVector([lt=isless], xs)
```

to sort `xs` and save the result in a vector. `xs` can be any `<: AbstractVector`. For immutable types (eg `StaticArrays.SVector` or `UnitRange`), `setindex!` will not work.

### Special constructors for checking or skipping sorting

If your code emits sorted vectors, use the
```julia
SortedVector(SortedVectors.AssumeSorted(), lt, sorted_contents)
```
constructor. This will skip checks.

If your API accepts sorted vectors, and you want to check them, use the
```julia
SortedVector(SortedVectors.CheckSorted(), lt, sorted_contents)
```
constructor.

**In either case, you are responsible for ensuring that the argument vector is not modified later on. `copy` if you are unsure.**

## Supported interfaces

### [`AbstractVector`](https://docs.julialang.org/en/v1/manual/interfaces/#man-interface-array-1)

`setindex!` verifies that sorting is maintained.
