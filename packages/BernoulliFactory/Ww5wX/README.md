# BernoulliFactory.jl

[![Build Status](https://travis-ci.org/awllee/BernoulliFactory.jl.svg?branch=master)](https://travis-ci.org/awllee/BernoulliFactory.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/x5w1kedalfn3f6wp/branch/master?svg=true)](https://ci.appveyor.com/project/awllee/bernoullifactory-jl/branch/master)
[![Coverage Status](https://coveralls.io/repos/github/awllee/BernoulliFactory.jl/badge.svg?branch=master)](https://coveralls.io/github/awllee/BernoulliFactory.jl?branch=master)
[![codecov.io](http://codecov.io/github/awllee/BernoulliFactory.jl/coverage.svg?branch=master)](http://codecov.io/github/awllee/BernoulliFactory.jl?branch=master)

This package provides some Bernoulli factory algorithms, and a constrained, unbiased estimation algorithm.

Given a function g such that g() returns a Bernoulli(p) variate, and a function f mapping [0,1] -> [0,1] a Bernoulli factory algorithm should use calls to g produce a Bernoulli(f(p)) variate. Not all functions f admit an algorithm (Keane & O'Brien, 1994), and some algorithms require additional information.

## Currently implemented

| Command | Description |
| --- | --- |
| f(p) = exp(-λp), λ >= 0 | `expMinus(g, λ)` |
| f(p) = p⁠^a, a >= 0 | `power(g, a)` |
| f(p) = C\*p / (1+C\*p), C > 0 | `logistic(g, C)` |
| f(p) = C\*p, ϵ ∈ (0, 1-C*p) | `linear(g, C, ϵ)` |
| f(p) = C/p, ϵ ∈ (0, p-C) | `inverse(g, C, ϵ)` |
| f(p1, p2) = C1\*p1 / (C1\*p1 + C2\*p2) | `twocoin(g1, g2, C1, C2)` |

### Constrained, unbiased estimation

Also implemented is a variant of signed estimation, `signedEstimate(μ, φ, a, b, δ, c, n)`:

Let X ~ μ and real-valued φ satisfy

a <= inf_x φ(x) < b < δ <= E[φ(X)] < sup_x φ(x) <= c,

with known (a, b, δ, c). If simulation from μ and evaluation of φ is feasible, one can simulate W satisfying

1. E[W] = E[φ(X)]
2. Pr(b <= W <= max{2b-a,c}) = 1

The random variable W is the product of two independent random variables, X and Z, and the positive integer parameter `n` specifies a number of averages to use to define X.

## Algorithms used

`expMinus` is an obvious extension of the approach described in Wastlund (1999) for λ=1.

`power` is from Mendo (2016).

`logistic` is from Huber (2017).

`linear` is from Huber (2016), and for a large range of parameter settings appears to use the least expected flips of all algorithms for this problem.

`inverse` is described in Lee, Doucet & Łatuszyński (2014).

`twocoin` is described in Gonçalves, Łatuszyński & Roberts (2017).

`signedEstimate` is described in Appendix C of Lee, Doucet & Łatuszyński (2014).

## Usage

All Bernoulli factory algorithms return a tuple `(X, flips)` where `X` is true or false and `flips` is the number of calls of `g()` by the algorithms.

`signedEstimate` returns a tuple `(X, flips, calls)` where `X` is true or false, `flips` is the number of Bernoulli factory flips and `calls` is the number of calls of `μ()` by the algorithms. `calls` is typically much larger thatn `flips`

## References

Gonçalves, F.B., Łatuszyński, K.G. and Roberts, G.O., 2017. Exact Monte Carlo likelihood-based inference for jump-diffusion processes. arXiv:1707.00332

Huber, M., 2016. Nearly optimal Bernoulli factories for linear functions. Combinatorics, Probability and Computing, 25(4), pp.577-591.

Huber, M., 2017. Optimal linear Bernoulli factories for small mean problems. Methodology and Computing in Applied Probability, 19(2), pp.631-645.

Keane, M.S. and O'Brien, G.L., 1994. A Bernoulli factory. ACM Transactions on Modeling and Computer Simulation (TOMACS), 4(2), pp.213-219.

Lee, A., Doucet, A. and Łatuszyński, K., 2014. Perfect simulation using atomic regeneration with application to Sequential Monte Carlo. arXiv:1407.5770

Mendo, L., 2016. An asymptotically optimal Bernoulli factory for certain functions that can be expressed as power series. arXiv:1612.08923

Wästlund, J., 1999. Functions arising by coin flipping. Technical Report, KTH, Stockholm.
