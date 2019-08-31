# ComplexValues

This package provides two additional types for representing complex values in Julia: a `Polar` type for representation in polar coordinates, and a `Spherical` type for representation on the Riemann sphere. Both types also affect plotting commands in the [Plots](https://github.com/JuliaPlots/Plots.jl) package.

## Examples

```@repl 1
using ComplexValues
Polar(1im)
Polar.(exp.(1im*LinRange(0,2π,6)))
Spherical(Inf)
```
A `Spherical` value can be converted to a 3-vector of coordinates on the unit sphere $S^2$.
```@repl 1
Spherical(0)
S2coord(ans)
```

### Plots

Plots of `Polar` type are as usual, but on polar axes.

```@example 1 
using Plots  # you must add this package first
zc = exp.(1im*2π*(0:500)/500);
plot(Polar.(0.5 .+ zc),legend=false)  
savefig("polar_circle.svg"); nothing # hide
```

![](polar_circle.svg)

```@example 1
zl = collect(LinRange(50-50im,-50+50im,601));
plot(Spherical.(zc/2),l=3,leg=false)  # plot on the Riemann sphere
plot!(Spherical.(-1 .+ zl),l=3)
savefig("sphere_plot.svg"); nothing # hide
```

![](sphere_plot.svg)

(Unfortunately, plotting backends and exports don't consistently support setting the aspect ratio in 3D. I've had success with `plotlyjs()` for interactive plots, though not when exporting them.)

## Usage notes

- Either of the two new types can be converted to a built-in complex floating number via `Complex`.
- Promotion of any number along with a `Spherical` value results in `Spherical`. 
- Promotion of any built-in number type with a `Polar` results in `Polar`. 
- Standard unary and binary functions in `Base` are extended to work with the new types. 
- The type `AnyComplex{T<:AbstractFloat}` is defined (but not exported) as the union of the built-in `Complex{T}` together with `Polar{T}` and `Spherical{T}`. 