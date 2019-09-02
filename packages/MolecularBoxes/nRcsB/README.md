# MolecularBoxes.jl

[![Build Status](https://travis-ci.org/tom--lee/MolecularBoxes.jl.svg?branch=master)](https://travis-ci.org/tom--lee/MolecularBoxes.jl)
[![Coverage Status](https://coveralls.io/repos/tom--lee/MolecularBoxes.jl/badge.svg?branch=master)](https://coveralls.io/r/tom--lee/MolecularBoxes.jl?branch=master)

MolecularBoxes is a Julia package providing tools for dealing with periodic 
boundary conditions when analysing molecular simulations.

For example, to create a rectangular box with periodic boundary conditions in 
x, y and z start a Julia REPL and enter:
```julia
julia> using MolecularBoxes

julia> using StaticArrays

julia> box_edge_length = SVector(3.0,4.0,5.0)
3-element SArray{Tuple{3},Float64,1,3}:
 3.0
 4.0
 5.0

julia> box = Box(box_edge_length)
Box{SArray{Tuple{3},Float64,1,3},3,(true, true, true)}(([3.0, 0.0, 0.0], [0.0, 4.0, 0.0], [0.0, 0.0, 5.0]), [3.0, 4.0, 5.0])
```

To get the vector separating two points according to the nearest image 
convention:

```julia
julia> v1 = SVector(0.1, 0.2, 0.3)
3-element SArray{Tuple{3},Float64,1,3}:
 0.1
 0.2
 0.3

julia> v2 = SVector(2.9, 3.9, 4.9)
3-element SArray{Tuple{3},Float64,1,3}:
 2.9
 3.9
 4.9

julia> separation(v1, v2, box)
3-element SArray{Tuple{3},Float64,1,3}:
 0.20000000000000018
 0.30000000000000027
 0.39999999999999947
```

`separation(v1, v2, box)` should be read as "the separation of `v1` from `v2` 
in `box`".

A box can also be defined with one or more fixed (ie non-periodic) boundaries 
in order to avoid applying the minimum image convention in that direction.

```julia
julia> box_fpf = Box(box_edge_length, periodic=(false, true, false))
Box{SArray{Tuple{3},Float64,1,3},3,(false, true, false)}(([3.0, 0.0, 0.0], [0.0, 4.0, 0.0], [0.0, 0.0, 5.0]), [3.0, 4.0, 5.0])

julia> separation(v1, v2, box_fpf)
3-element SArray{Tuple{3},Float64,1,3}:
 -2.8
  0.30000000000000027
 -4.6000000000000005
```

Finally, the center of mass of a collection of particles in a fully-periodic 
system can be calculated:
```julia
julia> center_of_mass([v1, v2], box) # assuming all particles have the same mass
3-element SArray{Tuple{3},Float64,1,3}:
 3.0
 0.04999999999999972
 0.10000000000000014

julia> center_of_mass([v1, v2], box, weights=[1.0, 2.0])
3-element SArray{Tuple{3},Float64,1,3}:
 2.9662270109017728
 3.999162045790778
 0.03205882409647218
```
