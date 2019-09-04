# TakagiFactorization.jl

[![Build Status](https://travis-ci.org/Element-126/TakagiFactorization.jl.svg?branch=master)](https://travis-ci.org/Element-126/TakagiFactorization.jl)
[![codecov.io](http://codecov.io/github/Element-126/TakagiFactorization.jl/coverage.svg?branch=master)](http://codecov.io/github/Element-126/TakagiFactorization.jl?branch=master)
[![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)

This package is a Julia translation of Thomas Hahn's Takagi factorization routine (http://www.feynarts.de/diag/).

Its main advantage (besides being written entirely in Julia) is that it can handle arbitrary precision arithmetics out of the box (e.g. using `BigFloat`).

All credit goes to the original author (except for bugs). If you use this package in your research, please cite:
  
* [*Routines for the diagonalization of complex matrices*, T. Hahn, arXiv:0607103](https://arxiv.org/abs/physics/0607103)

If you find any bugs, please file an issue here. Bonus points if you check that the bug is absent from the original version :)

Example usage:
---

```julia
using TakagiFactorization
using LinearAlgebra

A₁ = convert(Matrix{Complex{Float64}}, [1.0 2.0; 2.0 1.0])
d₁, U₁ = takagi_factor(A₁, sort=-1)
@assert A₁ ≈ transpose(U₁) * d₁ * U₁
@assert d₁ ≈ Diagonal([3.0, 1.0])
@assert U₁ ≈ [1 1; -1im 1im] / √2

# Using arbitrary precision
Base.MPFR.setprecision(512)
A₂ = convert(Matrix{Complex{BigFloat}}, [0.0 1.0; 1.0 0.0])
d₂, U₂ = takagi_factor(A₂)
@assert A₂ ≈ transpose(U₂) * d₂ * U₂
@assert d₂ ≈ Diagonal([1.0, 1.0])
@assert U₂ ≈ [1 1; -1im 1im] / √big(2)
```
