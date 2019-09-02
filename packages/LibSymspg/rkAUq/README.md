# LibSymspg.jl

[![Build Status](https://travis-ci.org/unkcpz/LibSymspg.jl.svg?branch=master)](https://travis-ci.org/unkcpz/LibSymspg.jl)

julia wrapper of library [spglib](https://github.com/atztogo/spglib)

Binary built by using [BinaryBuilder](https://github.com/JuliaPackaging/BinaryBuilder.jl) and provided by [BinaryProvider](https://github.com/JuliaPackaging/BinaryProvider.jl).

Now it is registered in [JuliaRegisties](https://github.com/JuliaRegistries/General), thus can be installed by running:

```sh
(v1.1) pkg> add LibSymspg
```

Lattice is represented as row vector,
while positions are represented as column vector which
compatible with spglib's C-API.

[Here](https://atztogo.github.io/spglib/definition.html) is the definition about how crystal transform when rotation and transformation applied.

```julia
using LibSymspg

latt = [-2.0 2.0 2.0; 2.0 -2.0 2.0; 2.0 2.0 -2.0]
positions = Array{Float64, 2}([0.0 0.0 0.0]')
types = [1]
latt, positions, types = refine_cell(latt, positions, types, 1e-5)
@test latt ≈ [4.0 0.0 0.0; 0.0 4.0 0.0; 0.0 0.0 4.0]
@test positions ≈ [0.0 0.5; 0.0 0.5; 0.0 0.5]
@test types == [1, 1]

# test determine the row and column type of latt and pos
# lattice is represented as row vectors
# positions represented as column vectors
latt = [4.0 0.0 0.0; 2.0 3.4641 0.0; 0.0 0.0 12.0]
positions = [0.0 1/3; 0.0 1/3; 0.0 1/3]
types = [1, 1]
num_atom = 2
@test get_spacegroup(latt, positions, types, 1e-3) == ("P-3m1", 164)
```
