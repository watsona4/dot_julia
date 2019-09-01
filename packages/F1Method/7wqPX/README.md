
<img src="https://user-images.githubusercontent.com/4486578/57202054-3d1c4400-6fe4-11e9-97d7-9a1ffbfcb2fc.png" alt="logo" title="F1method" align="right" height="200"/>

# F-1 Method

<p>
  <a href="https://doi.org/10.5281/zenodo.2667835">
    <img src="https://zenodo.org/badge/DOI/10.5281/zenodo.2667835.svg" alt="DOI">
  </a>
  <a href="https://github.com/briochemc/F1Method.jl/blob/master/LICENSE">
    <img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-yellow.svg">
  </a>
</p>
<p>
  <a href="https://briochemc.github.io/F1Method.jl/stable/">
    <img src=https://img.shields.io/badge/docs-stable-blue.svg>
  </a>
  <a href="https://briochemc.github.io/F1Method.jl/latest/">
    <img src=https://img.shields.io/badge/docs-dev-blue.svg>
  </a>
</p>
<p>
  <a href="https://travis-ci.com/briochemc/F1Method.jl">
    <img alt="Build Status" src="https://travis-ci.com/briochemc/F1Method.jl.svg?branch=master">
  </a>
  <a href='https://coveralls.io/github/briochemc/F1Method.jl'>
    <img src='https://coveralls.io/repos/github/briochemc/F1Method.jl/badge.svg' alt='Coverage Status' />
  </a>
</p>
<p>
  <a href="https://ci.appveyor.com/project/briochemc/f1method-jl">
    <img alt="Build Status" src="https://ci.appveyor.com/api/projects/status/prm2xfd6q5pba1om?svg=true">
  </a>
  <a href="https://codecov.io/gh/briochemc/F1Method.jl">
    <img src="https://codecov.io/gh/briochemc/F1Method.jl/branch/master/graph/badge.svg" />
  </a>
</p>

This package implements the F-1 method described in Pasquier et al. (in preparation).
It allows for efficient quasi-auto-differentiation of an objective function defined implicitly by the solution of a steady-state problem.

Consider a discretized system of nonlinear partial differential equations that takes the form

```
F(x,p) = 0
```

where `x` is a column vector of the model state variables and `p` is a vector of parameters.
The F-1 method then allows for an efficient computation of both the gradient vector and the Hessian matrix of a generic objective function defined by

```
objective(p) = f(s(p),p)
```

where `s(p)` is the steady-state solution of the system, i.e., such that `F(s(p),p) = 0` and where `f(x,p)` is for example a measure of the mismatch between observed state, parameters, and observations.
Optimizing the model is then simply done by minimizing `objective(p)`.
(See Pasquier et al., in prep., for more details.)

## Advantages of the F-1 method

The F-1 method is **easy** to use, gives **accurate** results, and is computationally **fast**:

- **Easy** — The F-1 method basically just needs the user to provide a solver (for finding the steady-state), the mismatch function, `f`, the state function, `F`, and their derivatives, `∇ₓf` and `∇ₓF` w.r.t. the state `x`. 
    (Note these derivatives can be computed numerically, via the [ForwardDiff](https://github.com/JuliaDiff/ForwardDiff.jl) package for example.) 
- **Accurate** — Thanks to dual and hyperdual numbers, the accuracy of the gradient and Hessian, as computed by the F-1 method, are close to machine precision.
    (The F-1 method uses the [DualNumbers](https://github.com/JuliaDiff/DualNumbers.jl) and [HyperDualNumbers](https://github.com/JuliaDiff/HyperDualNumbers.jl) packages.)
- **Fast** — The F-1 method is as fast as if you derived analytical formulas for every first and second derivatives *and* used those in the most efficient way.
    This is because the bottleneck of such computations is the number of matrix factorizations, and the F-1 method only requires a single one. In comparison, standard autodifferentiation methods that take the steady-state solver as a black box would require order `m` or `m^2` factorizations, where `m` is the number of parameters.

## What's needed?

A requirement of the F-1 method is that the Jacobian matrix `A = ∇ₓf` can be created, stored, and factorized.

To use the F-1 method, the user must:

- Make sure that there is a suitable algorithm `alg` to solve the steady-state equation
- overload the `solve` function and the `SteadyStateProblem` constructor from [DiffEqBase](https://github.com/JuliaDiffEq/DiffEqBase.jl). (An example is given in the CI tests — see, e.g., the [`test/simple_setup.jl`](test/simple_setup.jl) file.)
- Provide the derivatives of `f` and `F` with respect to the state, `x`.

## A concrete example

Make sure you have overloaded `solve` from DiffEqBase
(an example of how to do this is given in the [documentation](https://briochemc.github.io/F1Method.jl/stable/)).
Once initial values for the state, `x₀`, and parameters, `p₀`, are chosen, simply initialize the required memory cache, `mem` via

```julia
# Initialize the cache for storing reusable objects
mem = F1Method.initialize_mem(x₀, p₀)
```

wrap the functions into functions of `p` only via

```julia

# Wrap the objective, gradient, and Hessian functions
objective(p) = F1Method.objective(f, F, ∇ₓF, mem, p, myAlg(); my_options...)
gradient(p) = F1Method.gradient(f, F, ∇ₓf, ∇ₓF, mem, p, myAlg(); my_options...)
hessian(p) = F1Method.hessian(f, F, ∇ₓf, ∇ₓF, mem, p, myAlg(); my_options...)
```

and compute the objective, gradient, or Hessian via either of

```julia
objective(p₀)

gradient(p₀)

hessian(p₀)
```

That's it.
You were told it was simple, weren't you?
Now you can test how fast and accurate it is!
(Or trust our published work, Pasquier et al., in prep.)

## Citing the software

If you use this package, or implement your own package based on the F-1 method please cite us.
If you use the F-1 method, please cite our Pasquier et al. (in prep.) publication.
If you also use this package directly, please cite us using the [CITATION.bib](./CITATION.bib), which contains a bibtex entry for the software.
