# MaximumLikelihoodPower

Linux, OSX: [![Build Status](https://travis-ci.org/jlapeyre/MaximumLikelihoodPower.jl.svg)](https://travis-ci.org/jlapeyre/MaximumLikelihoodPower.jl)
&nbsp;
Windows: [![Build Status](https://ci.appveyor.com/api/projects/status/github/jlapeyre/MaximumLikelihoodPower.jl?branch=master&svg=true)](https://ci.appveyor.com/project/jlapeyre/maximumlikelihoodpower-jl)
&nbsp; &nbsp; &nbsp;
[![Coverage Status](https://coveralls.io/repos/github/jlapeyre/MaximumLikelihoodPower.jl/badge.svg?branch=master)](https://coveralls.io/github/jlapeyre/MaximumLikelihoodPower.jl?branch=master)
[![codecov.io](http://codecov.io/github/jlapeyre/MaximumLikelihoodPower.jl/coverage.svg?branch=master)](http://codecov.io/github/jlapeyre/MaximumLikelihoodPower.jl?branch=master)

Physicists love power laws. But, they don't always use the best methods for extracting powers
from empirical data.

### Notebook example

Here is a [notebook](http://nbviewer.jupyter.org/github/jlapeyre/MaximumLikelihoodPower.jl/blob/master/Notebooks/MLE_Pareto_distribution.ipynb) using `MaximumLikelihoodPower.jl` (this notebook is in the [Notebooks](Notebooks/) folder in this distribution).

### Command-line example

```julia
import MaximumLikelihoodPower
const MLE = MaximumLikelihoodPower

julia> seed = 11; α = 0.5;

# Get 10^6 samples from the Pareto distribution
julia> data = MLE.Example.makeparetodata(α, seed);

# Minimize the Kolmogorov-Smirnov statistic
# The second value returned is the minimizing alpha
julia> MLE.scanKS(data, range(.4, length=11, stop=.6))
3-element Array{Float64,1}:
 0.48
 0.5
 0.52
```

## Functions

### mle

```julia
    (estimate, stderr) = mle(data::AbstractVector)
```

Return the maximum likelihood estimate and standard error of the exponent of a power law
applied to the sorted vector `data`.

### KSstatistic

```julia
    KSstatistic(data::AbstractVector, alpha) --> Float64
```

Return the Kolmogorov-Smirnov statistic
comparing `data` to a power law with power `alpha`. The elements of `data` are
assumed to be unique. Minimizing the KS statistic over alpha is another way
to estimate the parameter of the sample distribution. See `testKS` in the
`test` directory.

### scanKS(data, powers)

Compute the Kolmogorov Smirnov statistic for several values of α in
the iterator `powers`. Return the value of α
that minimizes the KS statistic and the two neighboring values.

### mleKS

```julia
    mleKS{T<:AbstractFloat}(data::AbstractVector{T})
```

Return the maximum likelihood estimate and standard error of the exponent of a power law
applied to the sorted vector `data`. Also return the Kolmogorov-Smirnov statistic. Results
are returned in an instance of type `MLEKS`.

### scanmle

```julia
    scanmle(data::AbstractVector; ntrials=100, stderrcutoff=0.1, useKS=false)
````

Perform `mle` approximately `ntrials` times on `data`, increasing `xmin`. Stop trials
if the `stderr` of the estimate `alpha` is greater than `stderrcutoff`. Return an object
containing statistics about the scan.

### comparescan

```julia
    comparescan(mle::MLEKS, i, data, mlescan::MLEScan)
```
compare the results of MLE estimation `mle` to record results
in `mlescan` and update `mlescan`.

### Reference

Clauset, A., Shalizi, C. R., & Newman, M. E. J. (**2009**).
*Power-Law Distributions in Empirical Data*. SIAM Review, 51(4),
661–703. http://dx.doi.org/10.1137/070710111, https://arxiv.org/abs/0706.1062


<!--  LocalWords:  MaximumLikelihoodPower OSX nbsp codecov io
 -->
<!--  LocalWords:  mle stderr KSstatistic
 -->
