# Granular.jl

**A [Julia](https://julialang.org) package for particle-based simulation of 
granular materials.**

`Granular.jl` is a flexible and computationally efficient 2d implementation of 
the discrete element method.  Grains are represented as particles, which can be 
forced by drag in fluid grids.  The grains interact through 
elasto-viscous-frictional contact rheologies and can obtain time-dependent 
cohesive strength with bond mechanics based on beam theory.

The source code for Granular.jl is hosted on [Github](https://github.com/anders-dc/Granular.jl).

See the [Public API Index](@ref main-index) for the complete list of documented functions and types.

---

### Author
[Anders Damsgaard](https://adamsgaard.dk), Geophysical Fluid Dynamics Laboratory, Princeton University.

### License
Granular.jl is licensed under the GPLv3; see [LICENSE](https://github.com/anders-dc/Granular.jl/blob/master/LICENSE.md) for the full license text.

## Manual Outline

```@contents
Pages = [
    "man/installation.md",
    "man/package_contents.md",
    "man/methods.md",
    "man/getting_started.md",
]
Depth = 1
```

## Library Outline
```@contents
Pages = [
    "lib/public.md",
    "lib/internals.md",
]
Depth = 1
```
