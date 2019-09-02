# LargeMovieReviewDataset.jl

[![Build Status](https://travis-ci.org/dellison/LargeMovieReviewDataset.jl.svg?branch=master)](https://travis-ci.org/dellison/LargeMovieReviewDataset.jl) [![codecov](https://codecov.io/gh/dellison/LargeMovieReviewDataset.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/dellison/LargeMovieReviewDataset.jl)

A julia package that provides an interface to the [Large Movie Review Dataset](https://ai.stanford.edu/~amaas/data/sentiment/). Downloading and managing the data will happen automatically, courtesy of [DataDeps.jl](https://github.com/oxinabox/DataDeps.jl).

## Installation

LargeMovieReviewDataset.jl is registered, so it can be installed with Julia's package manager.

```julia-repl
julia> ]add LargeMovieReviewDataset
```

## Usage

LargeMovieReviewDataset.jl exports the following functions:

- `review_files`
- `trainfiles`
- `testfiles`
- `review_id`
- `review_rating`

```julia
julia> using LargeMovieReviewDataset
julia> for file in trainfiles()
           # ...
       end
```
