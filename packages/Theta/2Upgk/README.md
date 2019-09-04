# Theta.jl

| **Documentation** | **Build Status** |
|:-----------------:|:----------------:|
| [![](https://img.shields.io/badge/docs-dev-blue.svg)](https://chualynn.github.io/Theta.jl/dev) | [![Build Status](https://travis-ci.com/chualynn/Theta.jl.svg?branch=master)](https://travis-ci.com/chualynn/Theta.jl) |

Theta.jl is a Julia package for computing the Riemann theta function and its
derivatives.

For more information, refer to our upcoming preprint.

## Installation

Download Julia 1.1. Start Julia and run
```julia
julia> import Pkg
julia> Pkg.add("Theta")
```

## Examples
We start with a matrix `M` in the Siegel upper-half space.
```julia
M = [0.794612+1.9986im 0.815524+1.95836im 0.190195+1.21249im 0.647434+1.66208im 0.820857+1.68942im; 
0.0948191+1.95836im 0.808422+2.66492im 0.857778+1.14274im 0.754323+1.72747im 0.74972+1.95821im; 
0.177874+1.21249im 0.420423+1.14274im 0.445617+1.44248im 0.732018+0.966489im 0.564779+1.57559im; 
0.440969+1.66208im 0.562332+1.72747im 0.292166+0.966489im 0.433763+1.91571im 0.805161+1.46982im; 
0.471487+1.68942im 0.0946854+1.95821im 0.837648+1.57559im 0.311332+1.46982im 0.521253+2.29221im];      
```

We construct a `RiemannMatrix` using `M`.
```
R = RiemannMatrix(M);
```

We can then compute the theta function on inputs `z` and `M` as follows.
```
z = [0.30657351+0.34017115im; 0.71945631+0.87045964im; 0.19963849+0.71709398im; 0.64390182+0.97413482im; 0.02747232+0.59071266im];
theta(z, R)
```

We can also compute first derivatives of theta functions by specifying
the direction using the optional argument `derivs`. The following
code computes the partial derivative of the theta function with
respect to the first coordinate of `z`.
```julia
theta(z, R, derivs=[[1,0,0,0,0]])
```

We specify higher order derivatives by adding more elements into the
input to `derivs`, where each element specifies the direction of the
derivative. For instance, to compute the partial derivative of the
theta function with respect to the first, second and fifth coordinates
of `z`, we run
```julia
theta(z, R, derivs=[[1,0,0,0,0], [0,1,0,0,0], [0,0,0,0,1]])
```

We can compute theta functions with characteristics using the optional
argument `char`.
```julia
theta(z, R, char=[[0,1,0,1,1],[0,1,1,0,0]])
```

We can also compute derivatives of theta functions with
characteristics.
```julia
theta(z, R, derivs=[[1,0,0,0,0]], char=[[0,1,0,1,1],[0,1,1,0,0]])
```
