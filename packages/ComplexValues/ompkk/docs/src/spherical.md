# Spherical

A `Spherical` value stores the latitude and azimuthal angles. For efficiency, the angles are not converted to any standard interval, though some operations on values do so. They can be accessed directly as the `lat` and `lon` (for longitude) fields.

Multiplicative inverse (`inv`) and `sign` of `Spherical` values exploit the structure of the representation. Otherwise, most operations are done by first converting to `Complex`.

The comparators `iszero`, `isinf`, `isfinite`, and `isapprox` are defined appropriately.

Using `Plots`, a plot of `Spherical` values will be drawn on the surface of the unit sphere. The keyword `sphere` is used to control the additional plotting of a gray wireframe on the sphere. If set to `true` (the default), the number of latitude and longitude circles is chosen automatically; if set to a tuple, it determines the number of longitudinal and latitudinal circles, respectively. 

```@autodocs
Modules = [ComplexValues]
Order = [:type, :function]
Pages = ["spherical.jl"]
```
