# ArnoldiMethodTransformations

A package for easily interfacing with [ArnoldiMethod](https://github.com/haampie/ArnoldiMethod.jl), using the suggested [transformations](https://haampie.github.io/ArnoldiMethod.jl/stable/usage/02_spectral_transformations.html) suggested in the [documentation](https://haampie.github.io/ArnoldiMethod.jl/stable/index.html).


## Installation

In REPL, type either `] add git@github.com:wrs28/ArnoldiMethodTransformations.git` or
````JULIA
using Pkg
Pkg.add("git@github.com:wrs28/ArnoldiMethodTransformations.git")
````

This package does not export any new methods, it only extends some methods of [ArnoldiMethod](https://github.com/haampie/ArnoldiMethod.jl), which needs to be separately installed.

## Example
Ordinary eigenvalue problem `Ax=λx`
````JULIA
using LinearAlgebra, ArnoldiMethod, ArnoldiMethodTransformations

# construct fixed eval matrix in random basis
D = diagm(0=>[0,1,2,3,4,5,6,7,8,9])
S = randn(10,10)
A = S\D*S

# find eigenpairs closest to 5.001 (cannot be 5 as algorithm is unstable if σ is exactly an eval)
decomp, hist = partialschur(A,5.001)

# get evecs
λ, v = partialeigen(decomp,5.001)

display(decomp.eigenvalues)
norm(A*v-v*diagm(0=>decomp.eigenvalues))
# should be ~1e-11 or smaller
````

Generalized eigenvalue problem `Ax=λBx`
````JULIA
using LinearAlgebra, ArnoldiMethod, ArnoldiMethodTransformations

# construct fixed eval matrix in random basis
A = rand(ComplexF64,10,10)
B = rand(ComplexF64,10,10)

# find eigenpairs closest to .5
decomp, hist = partialschur(A,B,.5)

# get evecs
λ, v = partialeigen(decomp,.5)

display(decomp.eigenvalues)
norm(A*v-B*v*diagm(0=>decomp.eigenvalues))
# should be ~1e-14 or smaller
````

Note that in both cases, `ArnoldiMethod` needed to be explicitly brought into scope with `using`.

## Methods
This package exports none of its own methods, but extends `partialschur`  and `partialeigen` from [ArnoldiMethod](https://github.com/haampie/ArnoldiMethod.jl).

These are:
---------------
    `partialschur(A, [B], σ; [diag_inv_B, lupack=:auto, kwargs...]) -> decomp, history`

Partial Schur decomposition of `A`, with shift `σ` and mass matrix `B`, solving `A*v=σB*v`

Keyword `diag_inv_B` defaults to `true` if `B` is both diagonal and invertible. This enables
a simplified shift-and-invert scheme.

Keyword `lupack` determines what linear algebra library to use. Options are `:pardiso`, `:umfpack`, and the default `:auto`, which chooses based on availability at the top level, in this order: PARDISO >  UMFPACK. For example, if at the top level there is only `using ArnoldiMethod, ArnoldiMethodTransformations`, will default to UMFPACK, while the additional `using Pardiso` will default to `:pardiso`.

For other keywords, see `ArnoldiMethod.partialschur`

---------------
    partialeigen(decomp, σ)

Transforms a partial Schur decomposition into an eigendecomposition, but undoes the shift-and-invert of the eigenvalues by `σ`.


    partialeigen(A, [B], σ; [diag_inv_B, untransform=true, lupack=:auto, kwargs...]) -> λ, v, history

Partial eigendecomposition of `A`, with mass matrix `B` and shift `σ` , solving `A*v=λB*v` for the eigenvalues closest to `σ`

If keyword `untransform=true`, the shift-invert transformation of the eigenvalues is inverted before returning

Keyword `diag_inv_B` defaults to `true` if `B` is both diagonal and invertible. This enables a simplified shift-and-invert scheme.

Keyword `lupack` determines what linear algebra library to use. Options are `:pardiso`, `:umfpack`, and the default `:auto`, which chooses based on availability at the top level, in this order: PARDISO >  UMFPACK. For example, if at the top level there is only `using ArnoldiMethod, ArnoldiMethodTransformations`, will default to UMFPACK, while the additional `using Pardiso` will default to `:pardiso`.

For other keywords, `see ArnoldiMethod.partialschur`


------------
Note that the shifting to an exact eigenvalue poses a problem, see note on [purification](https://haampie.github.io/ArnoldiMethod.jl/stable/theory.html#Purification-1).


## Linear Solvers
There are two solvers currently available for use in this package: UMFPACK (via `Base.LinAlg`), and [Pardiso](https://pardiso-project.org) (via [`Pardiso`](https://github.com/JuliaSparse/Pardiso.jl)).

Pardiso is often faster, and uses significantly less memory, but require separate installation, which not all users will want to do. This optional dependency is implemented with [Requires.jl](https://github.com/MikeInnes/Requires.jl), and works like so: Pardiso is used for linear solve if `Pardiso` is loaded at the top level, else UMFPACK is used.

To do: add [MUMPS](http://mumps.enseeiht.fr) to the available solvers.
