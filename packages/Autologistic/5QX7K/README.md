# Autologistic

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://kramsretlow.github.io/Autologistic.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://kramsretlow.github.io/Autologistic.jl/dev)
[![Build Status](https://travis-ci.com/kramsretlow/Autologistic.jl.svg?branch=master)](https://travis-ci.com/kramsretlow/Autologistic.jl)
[![codecov](https://codecov.io/gh/kramsretlow/Autologistic.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/kramsretlow/Autologistic.jl)

A Julia package for computing with the autologistic (Ising) probability model
and performing autologistic regression.

Autologistic regression is like an extension of logistic regression that allows the binary
responses to be correlated.  An undirected graph is used to encode the association structure
among the responses.

The package follows the treatment of this model given in the paper
[Better Autologistic Regression](https://doi.org/10.3389/fams.2017.00024).  As described in
that paper, different variants of "the" autologistic regression model are actually different
probability models. One reason this package was created was to allow researchers to compare
the performance of the different model variants.  You can create different variants of
the model easily and fit them using either maximum likelihood (for small-n cases) or maximum
pseudolikelihood (for large-n cases).

At present only the most common "simple" form of the model--with a single parameter
controlling the association strength everywhere in graph--is implemented.  But the
package is designed to be extensible. In future different ways of parametrizing
the association could be added.

Much more detail is provided in the [documentation](https://kramsretlow.github.io/Autologistic.jl/stable).

```julia
# To get a feeling for the package facilities.
# The package uses LightGraphs.jl for graphs.
using Autologistic, LightGraphs
g = Graph(100, 400)            #-Create a random graph (100 vertices, 400 edges)
X = [ones(100) rand(100,3)]    #-A matrix of predictors.
Y = rand([0, 1], 100)          #-A vector of binary responses.
model = ALRsimple(g, X, Y=Y)   #-Create autologistic regression model

# Estimate parameters using pseudolikelihood. Do parametric bootstrap
# for error estimation.  Draw bootstrap samples using perfect sampling.
fit = fit_pl!(model, nboot=2000, method=perfect_read_once)

# Draw samples from the fitted model and get the average to estimate
# the marginal probability distribution. Use a different perfect sampling
# algorithm.
marginal = sample(model, 1000, method=perfect_bounding_chain, average=true)
```