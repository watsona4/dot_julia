# PerronFrobenius.jl

[![Build Status](https://travis-ci.org/kahaaga/PerronFrobenius.jl.svg?branch=master)](https://travis-ci.org/kahaaga/PerronFrobenius.jl)

A Julia package to compute approximation to the transfer operator
(Perron-Frobenius operator) and invariant measures from partitioned state
space reconstructions.

`PerronFrobenius.jl` provides essential functionality for the  [`CausalityTools.jl`](https://github.com/kahaaga/CausalityTools.jl) and
	and [`TimeseriesSurrogates.jl`](https://github.com/kahaaga/TimeseriesSurrogates.jl)
	packages.


## Transfer operator estimators
Currently, the following estimators are implemented. For details on

| Estimator  | Accepts  | Status on Julia 1.0 | Reference  |
|---|---|---|---|
| `transferoperator_grid` | `AbstractArray`, `AbstractEmbedding`  | Working | [Diego et al. (2018)](https://arxiv.org/abs/1811.01677) |
| `transferoperator_triang_approx`   | `AbstractTriangulation`  | Working  | [Diego et al. (2018)](https://arxiv.org/abs/1811.01677) |
| `transferoperator_triang_exact` | `AbstractTriangulation`  | Tests fail  | [Diego et al. (2018)](https://arxiv.org/abs/1811.01677) |

All estimators return an instance of a subtype of `AbstractTransferOperator`,
which is a `struct` with a single field `transfermatrix`.

### Grid estimator

The grid estimator accepts either
1. a two-dimension array where each column represents a point in the state space reconstruction, or
2. an instance of a subtype of `AbstractEmbedding`.

### Triangulation estimator
The triangulation estimators take `StateSpaceReconstruction.AbstractTriangulation` instances as inputs.

## (Natural) invariant measures
Obtaining the invariant measure from a transfer operator `TO` is done by calling
`left_eigenvector(TO)`. 
