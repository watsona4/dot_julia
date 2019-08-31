# WiltonInts84

Exact integration of potentials over a triangle and the intersection of a triangle with a ring shaped domain.

[![Build Status](https://travis-ci.org/krcools/WiltonInts84.jl.svg?branch=master)](https://travis-ci.org/krcools/WiltonInts84.jl)
[![codecov](https://codecov.io/gh/krcools/WiltonInts84.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/krcools/WiltonInts84.jl)


```math
\int_T |x-y|^n dy
```

Meant as the basis for singularity extraction type strategies for the computation of near singular integrals as encountered in the acoustic and electromagnetic boundary element method.

The methods here are generalisations of those described in:

[[1]](http://ieeexplore.ieee.org/xpls/abs_all.jsp?arnumber=1143304&tag=1) D. Wilton, S. Rao, A. Glisson, D. Schaubert, O. Al-Bundak, and C. Butler, “Potential integrals for uniform and linear source distributions on polygonal and polyhedral domains,” IEEE Transactions on Antennas and Propagation, vol. 32, no. 3, pp. 276–281, Mar. 1984.

For details on how the techniques described here where generalised and the implementation, see the Jupyter [notebook](http://nbviewer.jupyter.org/github/krcools/WiltonInts84.jl/blob/master/docs/notebooks/Wilton_integrals_up_to_arbitrary_degree.ipynb) in this repo.

## Usage Example

```julia
using WiltonInts84
using FixedSizeArrays

v1 = Vec(0.0, 0.0, 0.0)
v2 = Vec(1.0, 0.0, 0.0)
v3 = Vec(0.0, 1.0, 0.0)
n = normalize(cross(v1-v3,v2-v3))
x = (v1 + v2 + v3)/3 + 20n

I, J = wiltonints(v1,v2,v3,x,Val{7})
```

`I` will contain the integrals ``\int_T R^n`` and `J` will contain the integrals ``\int_T (\xi - y) R^n``, where ``\xi`` is the projection of ``x`` on the plane supporting ``T``. By virtue of a substantial amount of serendipity in the caluclations the vector case comes at almost no extra computational cost.

*note*: `I[1]` will contain the integral of ``hR^{-3}``, `I[2]` the integral of ``R^{-1}``, `I[i]` the integral of ``R^{i-3}`` for `i` larger or equal than `3`. The integral of ``R^{-2}`` is not computed. This is a special case that can only be expressed in terms of rather exotic special functions. Fortunately in boundary element methods this case never is required in the computation of interaction elements (not a coincidence I'm sure!). Users need to be aware however when indexing into the result.

*note*: The reason `I[1]` provides the integral of ``h/R^3`` including  the height of the singularity relative to the oriented triangle is to avoid infinities when `h` is zero. Instead the Cauchy principal value (which is zero for flat domains) is returned. Note that this means that as a function of `h` the integral of ``h/R^3`` is discontinuous at ``h = 0``.

*note*: In the example above points are provided by `FixedSizeArrays`. The code however does not rely upon this and any type complying to the vaguely defined notion of point semantics should work.

## Space-Time Galerkin Interaction Elements

In the implementation of time domain boundary element methods, one encounters integrals of the form

```math
\int_D R^n dy
\int_D R^n (y-x) dy
```

where ``D`` is the intersection of a triangle and a spherical shell centered around ``x``. This package can compute these integrals:

```julia
ctr = wiltonints(p1,p2,p3,x,r,R,Val{N})
```

The ability to compute these integrals was the main motivation for this package. A publicly avaible and well tested package I hope will render this class of integral equation based solvers more popular.
