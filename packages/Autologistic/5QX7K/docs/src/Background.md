# Background

This section provides a brief overview of the autologistic model, to establish some
conventions and terminology that will help you to make appropriate use of `Autologistic.jl`.

The package is concerned with the analysis of dichotomous data: categorical observations
that can take two possible values (low or high, alive or dead, present or absent, etc.).  
It is common to refer to such data as binary, and to use numeric values 0 and 1 to
represent the two states. We do not have to use 0 and 1, however: any other pair of numbers
could be used instead. This might seem like a small detail, but for autologistic
regression models, the choice of numeric coding is very important. The pair of
values used to represent the two states is called the **coding**.

!!! note "Important Fact 1"

    For ALR models, two otherwise-identical models that differ only in their coding will
    generally **not** be equivalent probability models.  Changing the coding fundamentally
    changes the model. For [a variety of reasons](https://doi.org/10.3389/fams.2017.00024),
    the ``(-1,1)`` coding is strongly recommended, and is used by default.

When responses are independent (conditional on the covariates), logistic regression is the
most common model. For cases where the independence assumption might not—responses are
correlated, even after including covariate effects—autologistic models are a useful
option.  They revert to logistic regression models when their association parameters are
set to zero.

## The Autologistic (AL) Model

Let ``\mathbf{Y}`` be a vector of ``n`` dichotomous random variables, expressed using any
chosen coding.  The AL model is a probability model for the joint probabiliyt mass function
(PMF) of the random vector:

```math
\Pr(\mathbf{Y}=\mathbf{y}) \propto \exp\left(\mathbf{y}^T\boldsymbol{\alpha} -
\mathbf{y}^T\boldsymbol{\Lambda}\boldsymbol{\mu} +
\frac{1}{2}\mathbf{y}^T\boldsymbol{\Lambda}\mathbf{y}\right)
```

The model is only specified up to a proportionality constant.  The proportionality constant
(sometimes called the "partition function") is intractable for even moderately large ``n``:
evaluating it requires computing the right hand side of the above equation for ``2^n``
possible configurations of the dichotomous responses.

Inside the exponential of the PMF there are three terms:

* The first term is the **unary** term, and ``\mathbf{\alpha}`` is called the
  **unary parameter**.  It summarizes each variable's endogenous tendency to take the "high"
  state. Larger positive ``\alpha_i`` values make random variable ``Y_i`` more likely to take
  the "high" value.  Note that in practical models, ``\mathbf{\alpha}`` could be expressed
  in terms of some other parameters.
* The second term is an optional **centering** term, and the value ``\mu_i`` is called the
  centering adjustment for variable ``i``.  The package includes different options
  for centering, in the [`CenteringKinds`](@ref) enumeration.  Setting centering to `none`
  will set the centering adjustment to zero; setting centering to `expectation` will use the
  centering adjustment of the "centered autologistic model" that has appeared in the
  literature (e.g. [here](https://link.springer.com/article/10.1198/jabes.2009.07032) and
  [here](https://doi.org/10.1002/env.1102)).

!!! note "Important Fact 2"

    Just as with coding, changing an un-centered model to a centered one is not a minor
    change.  It produces a different probability model entirely.  Again, there is evidence
    that [centering has drawbacks](https://doi.org/10.3389/fams.2017.00024), so the
    uncentered model is used by default.

* The third term is the **pairwise** term, which handles the association between the
  random variables.  Parameter ``\boldsymbol{\Lambda}`` is a symmetric matrix.  If it has
  a nonzero entry at position ``(i,j)``, then variables ``i`` and ``j`` share an edge in the
  graph associated with the model, and the value of the entry controls the strength of
  association between those two variables. ``\boldsymbol{\Lambda}`` can be parametrized in
  different ways.  The simplest and most common option is to let
  ``\boldsymbol{\Lambda} = \lambda\mathbf{A}``, where ``\mathbf{A}`` is the adjacency
  matrix of the graph.  This "simple pairwise" option has only a single association
  parameter, ``\lambda``.

The autogologistic model is a
[probabilistic graphical model](https://en.wikipedia.org/wiki/Graphical_model), more
specifically a [Markov random field](https://en.wikipedia.org/wiki/Markov_random_field),
meaning it has an undirected graph that encodes conditional probability relationships among
the variables. `Autologistic.jl` uses `LightGraphs.jl` to represent the graph.

## The Autologistic Regression (ALR) Model

The AL model becomes an ALR model when the unary parameter is written as a linear
predictor:

```math
\Pr(\mathbf{Y}=\mathbf{y}) \propto \exp\left(\mathbf{y}^T\mathbf{X}\boldsymbol{\beta} -
\mathbf{y}^T\boldsymbol{\Lambda}\boldsymbol{\mu} +
\frac{1}{2}\mathbf{y}^T\boldsymbol{\Lambda}\mathbf{y}\right)
```

where ``\mathbf{X}`` is a matrix of predictors/covariates, and ``\boldsymbol{\beta}``
is a vector of regression coefficients.

Note that because the responses are correlated, we treat each vector ``\mathbf{y}`` as
a single observation, consisting of a set of "variables," "vertices," or "responses." If
the number of variables is large enough, the model can be fit with only one observation.
With more than one observation, we can write the data as
``(\mathbf{y}_1, \mathbf{X}_1), \ldots (\mathbf{y}_m, \mathbf{X}_m)``. Each observation is
a vector with its own matrix of predictor values.  

## The Symmetric Model and Logistic Regression

Autologistic models can be expressed in a conditional log odds form.  If we let ``\pi_i`` be
the probability that variable ``i`` takes the high level, conditional on the values of all
of its neighbors, the model holds that

```math
\text{logit}(\pi_i) = (h-\ell)(\alpha_i + \sum_{j\sim i}\lambda_{ij}(y_j - \mu_j)),
```

where ``(\ell, h)`` is the coding, ``\lambda_{ij}`` is the ``(i,j)``th element of
``\Lambda``, and ``j\sim i`` means "all variables that are neighbors of ``i``".

The conditional form illustrates the link between ALR models and logistic
regression.  In the ALR model, ``\alpha_i = \mathbf{X}_i\boldsymbol{\beta}``.  If all
``\lambda_{ij}=0`` and the coding is ``(0,1)``, the model becomes a logistic regression
model.

If we fit an ALR model to a data set, it is natural to wonder how the regression
coefficients compare to the logistic regression model, which assumes independence.
Unfortunately, the coefficients of the preferred "symmetric" ALR model are not immediately
comparable to logistic regression coefficients, because it uses ``(-1,1)``
coding.  It is not hard to make the model comparable, however.

!!! note "The symmetric ALR model with (0,1) coding"

    The symmetric ALR model with ``(-1, 1)`` coding is equivalent to a model with ``(0,1)``
    coding and a constant centering adjustment of 0.5.

    If the original symmetric model has coefficients ``(β, Λ)``, the transformed model with
    ``(0,1)`` coding has coefficients ``(2β, 4Λ)``.  The transformed model's coefficients
    can be directly compared to logistic regression effect sizes.

    This means there are two ways to compare the symmetric ALR model to a logistic
    regression model. Either

    1. (recommended) Fit the ``(-1,1)`` `ALRsimple` model and transform the parameters, or

    2. Fit an `ALRsimple` model with `coding=(0,1)` and `centering=onehalf`.

Both of the above options are illustrated in the [Comparison to logistic regression](@ref)
section of the [Examples](@ref) in this manual.