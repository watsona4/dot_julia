# DualMatrixTools.jl Documentation

This package provides an overloaded `factorize` and `\` that work with dual-valued arrays.

It is essentially based on the dual type defined by the [DualNumbers.jl](https://github.com/JuliaDiff/DualNumbers.jl) package.

## Motivation

The idea is that for a dual-valued matrix ``M = A + \varepsilon B``, its inverse is given by
``M^{-1} = (I - \varepsilon_1 A^{-1} B) A^{-1}``.
Therefore, only the inverse of ``A`` is required to evaluate the inverse of ``M``.
This package should be useful for evaluation of first derivatives of functions that use `\` (e.g., with iterative solvers).

## How it works

[DualMatrixTools.jl](https://github.com/briochemc/DualMatrixTools.jl.git) makes available a `DualFactors` type which contains the factors of ``A`` (i.e., the output of `factorize`, e.g., ``L`` and ``U``, or ``Q`` and ``R``) and the non-real part of ``M`` (i.e., ``B``).
[DualMatrixTools.jl](https://github.com/briochemc/DualMatrixTools.jl.git) overloads `factorize` so that for a dual-valued matrix `M`, `factorize(M)` creates an instance of `DualFactors`.
Finally, [DualMatrixTools.jl](https://github.com/briochemc/DualMatrixTools.jl.git) also overloads `\` to efficiently solve dual-valued linear systems of the type ``M x = y`` by using the default `\` with the factors of ``A`` only.

## Usage

```@meta
DocTestSetup = quote
    using DualMatrixTools
end
```

Create your hyperdual-valued matrix `M`:
```jldoctest usage
n = 4
A, B = rand(n, n), randn(n, n)
M = A + ε * B
typeof(M)

# output

Array{DualNumbers.Dual{Float64},2}
```

Factorize `M`:
```jldoctest usage
Mf = factorize(M)
typeof(Mf)

# output

DualFactors
```

Apply `\` to solve systems of the type `M * x = y`
```jldoctest usage
y = rand(n, 2) * [1.0, ε]
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
DualFactors
```


