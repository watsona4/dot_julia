# Introduction

[MixedSubdivisions.jl](https://github.com/saschatimme/MixedSubdivisions.jl)
is package for computing a (fine) mixed subdivision and the [mixed volume](https://en.wikipedia.org/wiki/Mixed_volume) of lattice polytopes.
The mixed volume of lattice polytopes arising as Newton polytopes of a polynomial system
gives an upper bound of the number of solutions of the system. This is the celebrated
[BKK-Theorem](https://en.wikipedia.org/wiki/Bernstein–Kushnirenko_theorem).
A (fine) mixed subdivision can be used to efficiently solve sparse polynomial systems as
first described in [A Polyhedral Method for Solving Sparse Polynomial Systems](https://www.jstor.org/stable/2153370)
by Huber and Sturmfels.

There are many algorithms for computing mixed volumes and mixed subdivisions. This implementation
is based on the tropical homotopy continuation algorithm by Anders Jensen described in [arXiv:1601.02818](https://arxiv.org/abs/1601.02818).

## Installation

The package can be installed via the Julia package manager
```julia
pkg> add MixedSubdivisions
```

## Short introduction

We support polynomial input through the [DynamicPolynomials](https://github.com/JuliaAlgebra/DynamicPolynomials.jl) package.
```julia
@polyvar x y;
# create two polynomials
f = y^2 + x * y + x + 1;
g = x^2 + x * y + y + 1;

# mixed volume
mixed_volume([f, g])
```
```
4
```

Alternatively we could also give directly the supports to `mixed_volume`.
```julia
A = support([f, g])
```
```
2-element Array{Array{Int32,2},1}:
 [1 0 1 0; 1 2 0 0]
 [2 1 0 0; 0 1 1 0]
```
```julia
mixed_volume(A)
```
```
4
```


Now let's compute the mixed cells with respect to a given lift.

```julia
w₁ = [2, 0, 0, 0];
w₂ = [8, 4, 3, 0];
mixed_cells(A, [w₁, w₂])
```

```
2-element Array{MixedCell,1}:
 MixedCell:
 • volume → 3
 • indices → Tuple{Int64,Int64}[(2, 3), (4, 2)]
 • normal → [-2.66667, -1.33333]
 MixedCell:
 • volume → 1
 • indices → Tuple{Int64,Int64}[(3, 1), (1, 2)]
 • normal → [-6.0, -2.0]
```     

Now let's compare that to another lift.
```julia
v₁ = [1, 0, 0, 0];
v₂ = [8, 4, 3, 0];
mixed_cells(A, [v₁, v₂])
```
```
3-element Array{MixedCell,1}:
 MixedCell:
 • volume → 2
 • indices → Tuple{Int64,Int64}[(2, 1), (4, 2)]
 • normal → [-2.5, -1.5]
 MixedCell:
 • volume → 1
 • indices → Tuple{Int64,Int64}[(3, 1), (2, 4)]
 • normal → [-3.0, -1.0]
 MixedCell:
 • volume → 1
 • indices → Tuple{Int64,Int64}[(3, 1), (1, 2)]
 • normal → [-5.0, -1.0]
```

If you don't want to wait until all mixed cells got computed you can also use the
`MixedCellIterator`
```
for cell in MixedCellIterator(A, [v₁, v₂])
    println(cell)
end
```
```
MixedCell:
 • volume → 2
 • indices → Tuple{Int64,Int64}[(2, 1), (4, 2)]
 • normal → [-2.5, -1.5]
MixedCell:
 • volume → 1
 • indices → Tuple{Int64,Int64}[(3, 1), (2, 4)]
 • normal → [-3.0, -1.0]
MixedCell:
 • volume → 1
 • indices → Tuple{Int64,Int64}[(3, 1), (1, 2)]
 • normal → [-5.0, -1.0]
```


## API

```@docs
mixed_volume
MixedCell
volume
normal
indices
MixedCellIterator
mixed_cells
fine_mixed_cells
support
```
