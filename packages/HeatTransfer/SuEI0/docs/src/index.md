# HeatTransfer.jl

`HeatTransfer.jl` extends JuliaFEM functionalities to solve heat
transfer problems.

## Theory

The heat equation is a parabolic partial differential equation that
describes the distribution of heat (or variation in temperature) in
a given region over time. The state equation, given by the first law
of thermodynamics (i.e. conservation of energy), is written in the
following form (assuming no mass transfer or radiation). This form
is more general and particularly useful to recognize which property
(e.g. ``c_{p}`` or ``\rho``) influences which term. State equations is
```math
\rho c_{p}\frac{\partial T}{\partial t}-\nabla\cdot\left(k\nabla T\right)=\dot{q}_{V},
```
where ``\dot{q}_{V}`` is the volumetric heat source.

## Features

PlaneHeat. Thermal conductivity ``k`` can be set using field `thermal
conductivity`. Volumetric heat source ``\dot{q}_{V}`` can be set using
field `heat source`. Heat flux for boundary can be set using field
`heat flux`. 

## References

- Heat equation. (2018, January 5). In Wikipedia, The Free Encyclopedia. Retrieved 00:49, January 30, 2018, from https://en.wikipedia.org/w/index.php?title=Heat_equation&oldid=818847673
- Heat transfer. (2018, January 26). In Wikipedia, The Free Encyclopedia. Retrieved 00:48, January 30, 2018, from https://en.wikipedia.org/w/index.php?title=Heat_transfer&oldid=822415173
