# MultivariateFunctions

This implements single algebra and evaluation on Multivariate functions.
There are a few ways in which it can be used.
* This can be used for approximation functions. It can currently implement OLS functions, chebyshev polynomials, the schumaker shape preserving spline and basic interpolation schemes. It can also implement Recursive Partitioning and create Multivariate Adaptive Regression (MARS) Splines. It could be extended to implement other approximation schemes.
* As in the [StochasticIntegrals.jl](https://github.com/s-baumann/StochasticIntegrals.jl) package this package can be used to define functions that will be the integrands in stochastic integrals. This has the benefit that the means, variances & covariances implied by these stochastic integrals can be found analytically.
* All basic algebra and calculus on a MultivariateFunction can be done analytically.
* The Newton's method is implemented so that roots and optima can be found using analytical Jacobians and Hessians.

## Contents

```@contents
pages = ["index.md",
         "1_structs_and_limitations.md",
         "2_interpolation_methods.md",
         "3_approximation_methods.md",
         "4_examples_algebra.md",
         "5_examples_interpolation.md",
         "6_examples_approximation.md",
         "99_refs.md"]
Depth = 2
```
