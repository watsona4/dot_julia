# Destruct.jl 
[![Build Status](https://travis-ci.org/spalato/Destruct.jl.svg?branch=master)](https://travis-ci.org/spalato/Destruct.jl)
[![PkgEval.jl Status on Julia 0.6](http://pkg.julialang.org/badges/Destruct_0.6.svg)](http://pkg.julialang.org/?pkg=Destruct&ver=0.6)
[![PkgEval.jl Status on Julia 0.7](http://pkg.julialang.org/badges/Destruct_0.7.svg)](http://pkg.julialang.org/?pkg=Destruct&ver=0.7)

Destructuring arrays of tuples in Julia. Should work in Julia 0.6 - 1.0.

## Overview

Using julia's 'dot-call' syntax on functions with multiple return arguments
results in an array of tuples. Sometimes, you want the tuple of arrays instead,
preserving array shape.
This can be achieved using `destruct`, which converts an array of tuple to a
tuple of arrays.

Works with any tuples (ie: with elements of different types).

This single function doesn't really require it's package, maybe you can find it a better home.

## Example
```julia
julia> using Destruct; using BenchmarkTools
julia> f(a, b) = a+1im*b, a*b, convert(Int, round(a-b)); # some transform returing multiple values
julia> v = f.(rand(3,1), rand(1,4));
julia> typeof(v)
Array{Tuple{Complex{Float64},Float64,Int64},2}
julia> x, y, z = destruct(v);
julia> z
3×4 Array{Int64,2}:
 0  0  0  0
 1  0  1  1
 1  0  1  1
julia> v = f.(rand(500,1,1), rand(1,500,500));
julia> @btime destruct($v); # using BenchmarkTools
  1.396 s (7 allocations: 3.73 GiB)
```
Getting this out of the way:
```julia
julia> x, y, z = f.(rand(100,1,1), rand(1,100,100)) |> destruct;
```
## Performance
A common way to unpack Arrays of tuples uses the broadcast dot-call:
```julia
unpack_broadcast(w::Array{<:Tuple}) = Tuple((v->v[i]).(w) for i=1:length(w[1]))
```
However, this approach suffers from two problems: it doesn't access the elements
in the order they are stored in memory and has huge memory consumption for
Tuples with varying types (`Tuples` instead of `NTuples`).

This "broadcast unpack" takes between 1.5x and 2x longer than `destruct`
supplied here for arrays of `NTuples`. The performance gain is much larger 
for tuples of heterogenous types: in the 10x to 75x range, using 1/10th
of the memory.

See timing scripts: `timing.jl` and `comparative_timing.jl`.

## How does it work?
The `destruct` function uses macros from `Base.Cartesian` to allocate
destination arrays and iterate over all the things. The alternative
implementations using broadcast dot-call is available as `Destruct.unpack_broadcast`.
