[![Build Status](https://travis-ci.org/trappmartin/HilbertSchmidtIndependenceCriterion.jl.svg?branch=master)](https://travis-ci.org/trappmartin/HilbertSchmidtIndependenceCriterion.jl)
[![Coverage Status](https://coveralls.io/repos/github/trappmartin/HilbertSchmidtIndependenceCriterion.jl/badge.svg?branch=master)](https://coveralls.io/github/trappmartin/HilbertSchmidtIndependenceCriterion.jl?branch=master)
# Hilbert-Schmidt Independence Criterion (HSIC)

This package provides basic implementations of the Hilbert-Schmidt Independence Criterion (HSIC) for Julia 1.0.

## What is implemented
The package currently contains the following implementations:

- Gamma HSIC (HSIC with Gamma approximation) [1]

## Example

The gamma HSIC can be run using:

```julia
X = randn(1, 100) # rows are samples
Y = randn(1, 100) * 0.2 # rows are samples
p = 0.1 # p-value (level of test)
(value, threshold) = gammaHSIC(X, Y, α = p)
independent = value < threshold
```

## Reference
[1] Gretton, Arthur, et al. "A kernel statistical test of independence." Advances in Neural Information Processing Systems. 2007.
