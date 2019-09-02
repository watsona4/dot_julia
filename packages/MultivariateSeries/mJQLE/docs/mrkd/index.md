# MultivariateSeries

Package for the decomposition of tensors and polynomial-exponential series.

## Introduction

The package `MultivariateSeries.jl` provides tools for the manipulation of sequences
``(\sigma_{\alpha})_{\alpha} \in \mathbb{K}^{\mathbb{N}^{n}}`` indexed by multivariate
indices ``\alpha \in {\mathbb{N}^{n}}`` which are represented as series: 
```math
     \sigma(\mathbf{z}) = \sum_{\alpha \in {\mathbb{N}^{n}}} \sigma_{\alpha} \mathbf{z}^{\alpha}
```
Sometimes it is preferrable to associate the following series in ``\mathbf{y}`` to the sequence ``\sigma``:
```math
\sigma(\mathbf{y}) = \sum_{\alpha \in {\mathbb{N}^{n}}} \sigma_{\alpha} \frac{\mathbf{y}^{\alpha}}{\alpha!}
```
    
The sequence ``\sigma`` or the series ``\sigma(z)`` represents a linear functional on the polynomials:
```math
     \sigma: p= \sum_{\alpha \in \mathbb{N}^n} p_{\alpha} \mathbf{x}^{\alpha} \mapsto \sum_{\alpha \in \mathbb{N}^n} p_{\alpha} \sigma_{\alpha}
```
The series are represented as association tables (or dictionnary) between (a finite set of) monomials and coefficients.
They are printed using dual variables `dxi`:

    using MultivariateSeries
    X = @ring x1 x2

    julia> p = (1+x1)^3 + 0.5*(1+x1+x2)^2
    x1³ + 3.5x1² + x1x2 + 0.5x2² + 4.0x1 + x2 + 1.5

    julia> sigma = dual(p)
    dx1^3 + 1.5 + 3.5dx1^2 + 4.0dx1 + dx2 + dx1*dx2 + 0.5dx2^2

Since the series is represented by a table, the order in which the dual monomials are
printed is the order used in the table. It is not necessarily sorted by a monomial ordering.

    julia> sigma.terms
    Dict{Monomial{true},Float64} with 7 entries:
       x1³  => 1.0
       1    => 1.5
       x1²  => 3.5
       x1   => 4.0
       x2   => 1.0
       x1x2 => 1.0
       x2²  => 0.5
    
Series act as linear functionals on polynomials via the dot product:
    
    julia> dot(sigma,x1^2)
    3.5
    julia> dot(sigma,x2^4)
    0.0

### Polynomial-exponential decomposition        
The package provide tools for solving the following decomposition problem:

Given (the first terms of) sequence ``\sigma \in \mathbb{K}^{\mathbb{N}^{n}}`` or the series 
``\sigma(\mathbf{y}) \in \mathbb{K}[[\mathbf{y}]]``, we want to decompose it as polynomial-exponential series 
```math
\sigma(\mathbf{y}) = \sum_{i=1}^r \omega_i(\mathbf{y}) e^{\xi_{i,1} y_1+ \cdots + \xi_{i,n} y_n}
```
with polynomials ``\omega_{i}(\mathbf{y})`` and points ``\xi_{i}= (\xi_{i,1}, \ldots, \xi_{i,n})\in \mathbb{K}^{n}``.  ``\omega_i`` are called the weights and  ``\xi_i`` the frequencies of the decomposition.


These types of decompositions appear in many problems (see [Examples](@ref sec_examples)). 

The package `MultivariateSeries` provides functions to manipulate (truncated) series, to construct truncated Hankel matrices, and to compute such a decomposition from these Hankel matrices.

## [Examples](@id sec_examples)

```@contents
Pages = map(file -> joinpath("expl", file), filter(x ->endswith(x, "md"), readdir("expl")))
```


## Functions and types

```@contents
Pages = map(file -> joinpath("code", file), filter(x ->endswith(x, "md"), readdir("code"))) 
```

## [Installation](@id sec_installation)

The package is available at [https://github.com/bmourrain/MultivariateSeries.jl.git](https://github.com/bmourrain/MultivariateSeries.jl.git)


To install it from Julia:
```julia
using Pkg
Pkg.clone("https://github.com/bmourrain/MultivariateSeries.jl.git")
```
It can then be used as follows:
```julia
using MultivariateSeries
```
See the [Examples](@ref sec_examples) for more details.


## Dependencies

The package `MultivariateSeries` depends on the following packages:

- `DynamicPolynomials` package on multivariate polynomials represented as lists of monomials.
- `MultivariatePolynomials` generic interface package for multivariate polynomials.

These packages will be installed with `MultivariateSeries`  (see [installation](@ref sec_installation)).

        
