# Discreet

[![Build Status](https://travis-ci.org/cynddl/Discreet.jl.svg?branch=master)](https://travis-ci.org/cynddl/Discreet.jl)
[![Coverage Status](https://coveralls.io/repos/cynddl/Discreet.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/cynddl/Discreet.jl?branch=master)
[![codecov.io](http://codecov.io/github/cynddl/Discreet.jl/coverage.svg?branch=master)](http://codecov.io/github/cynddl/Discreet.jl?branch=master)

Discreet is a small opinionated toolbox to estimate entropy and mutual information from discrete samples. It contains methods to adjust results and correct over- or under-estimations.

The code here should work on Julia 0.6. It has minimal unit tests and has received little testing in the wild.g

## Estimating entropy

Discreet uses StatsBase's FrequencyWeights and ProbabilityWeights types.

```julia
using StatsBase: FrequencyWeights, ProbabilityWeights
using Discreet

dist = FrequencyWeights([1, 1, 1, 1, 1, 1])
entropy(dist)  # Naive method: log(6) ≈ 1.792

entropy(dist; method=:CS)  # Chao-Shen correction: ≈ 3.840

entropy(dist; method=:Shrink)  # Shrinkage correction: ≈ 1.792

dist = ProbabilityWeights([.5, .5])
entropy(dist)  # log(2) ≈ 0.693
```

Discreet can also estimate the entropy of a sample:

```julia
using Discreet

data = ["tomato", "apple", "apple", "banana", "tomato"]
estimate_entropy(data)  # == entropy(FrequencyWeights([2, 2, 1]))
```

## Estimate mutual information

Discrete provides similar routines to estimate mutual information.

```julia
using Discreet

labels_a = [1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3]
labels_b = [1, 1, 1, 1, 2, 1, 2, 2, 2, 2, 3, 1, 3, 3, 3, 2, 2]
mutual_information(labels_a, labels_b)  # Naive method: ≈ 0.410

mutual_information(labels_a, labels_b; method=:CS)  # Chao-Shen correction: ≈ 0.148

mutual_information(labels_a, labels_b; normalize=true)  # Normalized score (between 0 and 1): ≈ 0.382
```
