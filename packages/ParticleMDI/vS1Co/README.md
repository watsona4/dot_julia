# ParticleMDI.jl

[![Build Status](https://travis-ci.org/nathancunn/ParticleMDI.jl.svg?branch=master)](https://travis-ci.org/nathancunn/ParticleMDI.jl)

This package provides an implementation of ParticleMDI, a particle Gibbs version of MDI, allowing for the integrative cluster analysis of multiple datasets. ParticleMDI is built within the framework of [MDI (multiple data integration)](https://academic.oup.com/bioinformatics/article/28/24/3290/244641).

## Installation
```jl
] add "git://github.com/nathancunn/ParticleMDI.jl.git"
```

## Usage
The function `pmdi()` provides the primary functionality for `ParticleMDI`. It requires the specification of:
- `dataFiles::Vector` a vector of K data matrices to be analysed
- `dataTypes::Vector` a vector of K datatypes. Independent multivariate normals can be
specified with `ParticleMDI.gaussianCluster`
- `N::Int64` the maximum number of clusters to fit
- `particles::Int64` the number of particles
- `ρ::Float64` proportion of allocations assumed known in each MCMC iteration
- `iter::Int64` number of iterations to run
- `outputFile::String` specification of a CSV file to store output
- `featureSelect::Bool` defaults to `false`, setting `true` means feature selection will be performed.

## Output
Outputs a .csv file, each row containing:
- Mass parameter for datasets `1:K`
- Φ value for `binomial(K, 2)` pairs of datasets
- c cluster allocations for observations `1:n` in datasets `1:k`

```jl
using ParticleMDI
using RDatasets

data = [Matrix(dataset("datasets", "iris")[:, 1:4])]
gaussian_normalise!(data[1])
dataTypes = [ParticleMDI.GaussianCluster]
pmdi(data, dataTypes, 10, 2, 0.99, 1000, "output/file.csv", true)
```

## Extending ParticleMDI for user-defined data types
`ParticleMDI` includes functionality for clustering Gaussian and categorical data, however this can easily be extended to other data types. Consider a trivial case where we wish to cluster data according to their sign.
The first step is to define a struct containing each cluster. Typically this will contain information on the number of observations in the cluster as well sufficient statistics for calculating the posterior predictive of assigning new observations to this cluster.

```jl
mutable struct SignCluster
  n::Int64    # No. of observations in cluster
  isneg::Bool # Positive/negative flag
  SignCluster(dataFile) = new(0, false)
end
```

Given this, we then need to define a function which returns the log posterior predictive of an observation belonging to this cluster, given the allocations already assigned to it. In this case, all we need to know is does the cluster contain positive or negative numbers. 

```jl
function ParticleMDI.calc_logprob(obs, cl::SignCluster)
    if cl.n == 0
        return log(0.5)
    else
        return ((obs[1] <= 0) == cl.isneg) ? 0 : - 10
    end
end
```

And finally, a function needs to be specified explaining how to update a cluster when new observations are added to it.
```jl
function ParticleMDI.cluster_add!(cl::SignCluster, obs)
    cl.n += 1
    cl.isneg = (obs[1] < 0)
end
```

Optionally a function which returns the log marginal likelihood of each feature in a cluster. This is used to perform feature selection by comparison between the inferred allocations and the situation where all observations within a feature are assigned to a single cluster. This need not be specified if `featureSelect = false`, however if you want to do feature selection for _any_ dataType you'll need to have this specified. In such a case, you can specify this to return a large number (**not** `Inf`) and features should always be selected. The assumption of independence across features underlies this step and so should not be used if this assumption does not hold.

```jl
function ParticleMDI.calc_logmarginal!(cl::SignCluster)
    # return a vector of log-marginal likelihoods
end
```

This can then be run by specifying `SignCluster` as a data type in `pmdi()`.
