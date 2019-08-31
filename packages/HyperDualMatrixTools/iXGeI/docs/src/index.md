# HyperDualMatrixTools.jl Documentation

This package provides an overloaded `factorize` and `\` that work with hyperdual-valued arrays.

It is essentially base on the hyper dual type defined by the [HyperDualNumbers.jl](https://github.com/JuliaDiff/HyperDualNumbers.jl) package.

## Motivation

The idea is that for a hyperdual-valued matrix ``M = A + \varepsilon_1 B + \varepsilon_2 C + \varepsilon_1 \varepsilon_2 D``, its inverse is given by
``M^{-1} = (I - \varepsilon_1 A^{-1} B - \varepsilon_2 A^{-1} C - \varepsilon_1\varepsilon_2 A^{-1} (D - B A^{-1} C - C A^{-1} B)) A^{-1}``.
Therefore, only the inverse of ``A`` is required to evaluate the inverse of ``M``.
This package should be useful for evaluation of second derivatives of functions that use `\` (e.g., with iterative solvers).

## How it works

[HyperDualMatrixTools.jl](https://github.com/briochemc/HyperDualMatrixTools.jl.git) makes available a `HyperDualFactors` type which contains the factors of ``A`` (i.e., the output of `factorize`, e.g., ``L`` and ``U``, or ``Q`` and ``R``) and the non-real parts of ``M`` (i.e., ``B``, ``C``, and ``D``).
[HyperDualMatrixTools.jl](https://github.com/briochemc/HyperDualMatrixTools.jl.git) overloads `factorize` so that for a hyperdual-valued matrix `M`, `factorize(M)` creates an instance of `HyperDualFactors`.
Finally, [HyperDualMatrixTools.jl](https://github.com/briochemc/HyperDualMatrixTools.jl.git) also overloads `\` to efficiently solve hyperdual-valued linear systems of the type ``M x = y`` by using the default `\` with the factors of ``A`` only.

## Usage

```@meta
DocTestSetup = quote
    using HyperDualMatrixTools
end
```

Create your hyperdual-valued matrix `M`:
```jldoctest usage
n = 4
A, B, C, D = rand(n, n), randn(n, n), rand(n, n), randn(n, n)
M = A + ε₁ * B + ε₂ * C + ε₁ε₂ * D
typeof(M)

# output

Array{HyperDualNumbers.Hyper{Float64},2}
```
(The `ε₁`, `ε₂`, and `ε₁ε₂` constants are provided by [HyperDualMatrixTools.jl](https://github.com/briochemc/HyperDualMatrixTools.jl.git) for convenience.)

Factorize `M`:
```jldoctest usage
Mf = factorize(M)
typeof(Mf)

# output

HyperDualFactors
```

Apply `\` to solve systems of the type `M * x = y`
```jldoctest usage
y = rand(n, 4) * [1.0, ε₁, ε₂, ε₁ε₂]
x = Mf \ y
M * x ≈ y

# output

true
```

## Functions

```@docs
factorize
```

```@docs
\
```

## New types

```@docs
HyperDualFactors
```


