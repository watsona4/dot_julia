# UnitfulMR

A supplemental units package of [Julia](https://julialang.org)'s [Unitful.jl](https://github.com/PainterQubits/Unitful.jl) for magnetic resonance (MR) usages.

## Defined units and usage

After importing:

```julia
julia> using Unitful, UnitfulMR
```

* [Gauss](https://en.wikipedia.org/wiki/Gauss_(unit))

```julia
julia> (1u"Gauss" == 100u"μT") && (1u"Gauss" == 1e-4u"T")
true
```

* [ppm](https://en.wikipedia.org/wiki/Parts-per_notation) (to be added)
* (More. You are welcomed to contribute.)

## Why making this package

[Unitful.jl](https://github.com/PainterQubits/Unitful.jl) seems to encourage making extension packages,
for lighter modules and cleaner namespaces, rather than suggesting individual units to be added to it.
