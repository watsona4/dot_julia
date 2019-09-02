[![Build Status](https://travis-ci.org/sadit/KernelMethods.jl.svg?branch=master)](https://travis-ci.org/sadit/KernelMethods.jl)
[![Coverage Status](https://coveralls.io/repos/github/sadit/KernelMethods.jl/badge.svg?branch=master)](https://coveralls.io/github/sadit/KernelMethods.jl?branch=master)
[![codecov](https://codecov.io/gh/sadit/KernelMethods.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/sadit/KernelMethods.jl)
# Kernel Methods


KernelMethods.jl is a library that implements and explores Kernel-Based Methods for _supervised learning_ and _semi-supervised learning_.

## Install

To start using `KernelMethods.jl` just type into an active Julia session

```julia
using Pkg
pkg"add https://github.com/sadit/KernelMethods.jl"

using KernelMethods

```

## Usage

`KernelMethods.jl` consists of a few modules

- `KernelMethods.Scores`. It contains several common performance measures, i.e., accuracy, recall, precision, f1, precision_recall.
- `KernelMethods.CrossValidation`. Some methods to perform cross validation, all of them work through callback functions:
   - `montecarlo`
   - `kfolds`
- `KernelMethods.Supervised`. It contains methods related to supervised learning
   - `NearNeighborClassifier`. It defines a `KNN` classifier
   - `optimize!`
   - `predict`
   - `predict_proba`

The distance functions are mostly taken from:
- `SimilaritySearch`

### Dependencies
KernelMethods.jl depends on

- [SimilaritySearch.jl](https://github.com/sadit/SimilaritySearch.jl)


## Final notes ##
To reach maximum performance, please ensure that Julia has access to the specific instruction set of your CPUs

[http://docs.julialang.org/en/latest/devdocs/sysimg/](http://docs.julialang.org/en/latest/devdocs/sysimg/)
