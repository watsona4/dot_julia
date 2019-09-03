# RiemannTheta.jl

|Julia versions | master build | Coverage |
|:-------------:|:------------:|:--------:|
|[![RiemannTheta](http://pkg.julialang.org/badges/RiemannTheta_0.7.svg)](http://pkg.julialang.org/?pkg=RiemannTheta&ver=0.7) [![RiemannTheta](http://pkg.julialang.org/badges/RiemannTheta_1.0.svg)](http://pkg.julialang.org/?pkg=RiemannTheta&ver=1.0)  | [![Build Status](https://travis-ci.org/fredo-dedup/RiemannTheta.jl.svg?branch=master)](https://travis-ci.org/fredo-dedup/RiemannTheta.jl) [![Build status](https://ci.appveyor.com/api/projects/status/87uu6gk6dp6dr3q9/branch/master?svg=true)](https://ci.appveyor.com/project/fredo-dedup/riemanntheta-jl/branch/master) | [![Coverage Status](https://coveralls.io/repos/github/fredo-dedup/RiemannTheta.jl/badge.svg?branch=master)](https://coveralls.io/github/fredo-dedup/RiemannTheta.jl?branch=master) |

Julia implementation of the Riemann Theta function. This package is mostly a port
from Python of the same function in the Sage library `Abelfunction`
(https://github.com/abelfunctions/abelfunctions). Beyond a given problem size (number of z
in zs, dimension of z's, number of integration  points), the functions switch to a different algorithm
using matrix operations resulting in very competitive timings (at the cost of memory usage).

The Sage library is itself an implementation of :


> [CRTF] B. Deconinck, M.  Heil, A. Bobenko, M. van Hoeij and M. Schmies,
> Computing Riemann Theta Functions, Mathematics of Computation, 73, (2004),
> 1417-1442.

Exported function are :

```julia
     riemanntheta(zs::Vector{Vector{Complex128}},
                  Ω::Matrix{Complex128};
                  eps::Float64=1e-8,
                  derivs::Vector{Vector{Complex128}}=Vector{Complex128}[],
                  accuracy_radius::Float64=5.)::Vector{Complex128}
```

Return the value of the Riemann theta function for Ω and all z in `zs` if
`derivs` is empty, or the derivatives at all z in `zs` for the given directional
derivatives in `derivs`.

_Parameters_ :
- `zs` : A vector of complex vectors at which to evaluate the Riemann theta function.
- `Omega` : A Riemann matrix.
- `eps` : (Default: 1e-8) The desired numerical accuracy.
- `derivs` : A vector of complex vectors giving a directional derivative.
- `accuracy_radius` : (Default: 5.) The radius from the g-dimensional origin
where the requested accuracy of the Riemann theta is guaranteed when computing
derivatives. Not used if no derivatives of theta are requested.


```julia
     oscillatory_part(zs::Vector{Vector{Complex128}},
                      Ω::Matrix{Complex128};
                      eps::Float64=1e-8,
                      derivs::Vector{Vector{Complex128}}=Vector{Complex128}[],
                      accuracy_radius::Float64=5.)::Vector{Complex128}
```

Return the value of the oscillatory part of the Riemann theta function for Ω and
all z in `zs` if `derivs` is empty, or the derivatives at all z in `zs` for the
given directional derivatives in `derivs`.

_Parameters_ :
- `zs` : A vector of complex vectors at which to evaluate the Riemann theta function.
- `Omega` : A Riemann matrix.
- `eps` : (Default: 1e-8) The desired numerical accuracy.
- `derivs` : A vector of complex vectors giving a directional derivative.
- `accuracy_radius` : (Default: 5.) The radius from the g-dimensional origin
where the requested accuracy of the Riemann theta is guaranteed when computing
derivatives. Not used if no derivatives of theta are requested.


And :

```julia
     exponential_part(zs::Vector{Vector{Complex128}},
                      Ω::Matrix{Complex128})::Vector{Float64}
```

Return the value of the exponential part of the Riemann theta function for Ω and
all z in `zs`.

_Parameters_ :
- `zs` : A vector of complex vectors at which to evaluate the Riemann theta function.
- `Omega` : A Riemann matrix.
