# DatasetsCF.jl - Collection of Collaborative Datasets

[![Build Status](https://travis-ci.org/JuliaRecsys/DatasetsCF.jl.svg?branch=master)](https://travis-ci.org/JuliaRecsys/DatasetsCF.jl)
[![Coverage Status](https://coveralls.io/repos/JuliaRecsys/DatasetsCF.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/JuliaRecsys/DatasetsCF.jl?branch=master)
[![codecov.io](http://codecov.io/github/JuliaRecsys/DatasetsCF.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaRecsys/DatasetsCF.jl?branch=master)

**Installation**: at the Julia REPL, `Pkg.add("DatasetsCF")`

**Reporting Issues and Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md)

## Example

```
julia> using DatasetsCF

julia> dataset = DatasetsCF.MovieLens();

julia> using Persa

julia> using Statistic

julia> μ = mean(dataset)
3.52986
```

## Datasets

List of package datasets:

Dataset      | Title
-------------|------------------------------------------------------------------------
MovieLens 100k  | This is a set of 100,000 ratings given by a set of users to a set of movies.
MovieLens 1M    | This is a set of 10,000,000 ratings given by a set of users to a set of movies.
