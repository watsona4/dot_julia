# Introduction

The `Autologistic.jl` package provides tools for analyzing correlated binary data using
autologistic (AL) or autologistic regression (ALR) models.  The AL model is a multivariate
probability distribution for dichotomous (i.e., two-valued) categorical responses. The ALR models incorporate covariate effects into this distribution and are therefore more useful for data
analysis.

The ALR model is potentially useful for any situation involving correlated binary responses.
It can be described in a few ways.  It is:

* An extension of logistic regression to handle non-independent responses.
* A Markov random field model for dichotomous random variables, with covariate effects.
* An extension of the Ising model to handle different graph structures and
  to include covariate effects.
* The quadratic exponential binary (QEB) distribution, incorporating
  covariate effects.

This package follows the treatment of this model given in the paper
[Better Autologistic Regression](https://doi.org/10.3389/fams.2017.00024).  Please refer
to that article for in-depth discussion of the model, and please cite it if you use this
package in your research.  The [Background](@ref) section in this manual also provides an
overview of the model.

## Contents

```@contents
Pages = ["index.md", "Background.md", "Design.md", "BasicUsage.md", "Examples.md", "api.md"]
Depth = 2
```

## Reference Index

The following topics are documented in the [Reference](@ref) section:

```@index
```