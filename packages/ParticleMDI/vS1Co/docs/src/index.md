# particleMDI.jl

This package provides an implementation of particleMDI, a particle Gibbs version of MDI, allowing for the integrative cluster analysis of multiple datasets. particleMDI is built within the framework of [MDI (multiple data integration)](https://academic.oup.com/bioinformatics/article/28/24/3290/244641).

## Installation
```jl
Pkg.clone("git://github.com/nathancunn/particleMDI.jl.git")
```

## Usage
The function `pmdi()` provides the primary functionality for `particleMDI`. It requires the specification of:
- `dataFiles::Vector` a vector of K data matrices to be analysed
- `dataTypes::Vector` a vector of K datatypes. Independent multivariate normals can be
specified with `particleMDI.gaussianCluster`
- `N::Int64` the maximum number of clusters to fit
- `particles::Int64` the number of particles
- `ρ::Float64` proportion of allocations assumed known in each MCMC iteration
- `iter::Int64` number of iterations to run
- `outputFile::String` specification of a CSV file to store output
- `initialise::Bool` if false, the algorithm begins at last output recorded in
`outputFile` otherwise begin fresh.
## Output
Outputs a .csv file, each row containing:
- Mass parameter for datasets `1:K`
- Φ value for `binomial(K, 2)` pairs of datasets
- c cluster allocations for observations `1:n` in datasets `1:k`

```jl
using particleMDI
using RDatasets

data = [Matrix(dataset("datasets", "iris")[:, 1:4])]
gaussian_normalise!(data[1])
dataTypes = [particleMDI.GaussianCluster]
pmdi(data, dataTypes, 10, 2, 0.99, 1000, "output/file.csv", true)
```

## Extending particleMDI for user-defined data types
`particleMDI` includes functionality for clustering Gaussian and categorical data, however this can easily be extended to other data types. Consider a trivial case where we wish to cluster data according to their sign.
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
function particleMDI.calc_logprob(cl::SignCluster, obs)
    if cl.n == 0
        return log(0.5)
    else
        return ((obs[1] <= 0) == cl.isneg) ? 0 : - 10
    end
end
```

And finally, a function needs to be specified explaining how to update a cluster when new observations are added to it.
```jl
function particleMDI.cluster_add!(cl::SignCluster, obs)
    cl.n += 1
    cl.isneg = (obs[1] < 0)
end
```

This can then be run by specifying `SignCluster` as a data type in `pmdi()`.
