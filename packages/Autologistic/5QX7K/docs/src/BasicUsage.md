# Basic Usage

Typical usage of the package will involve the following three steps:

**1. Create a model object.**

All particular AL/ALR models are instances of subtypes of
[`AbstractAutologisticModel`](@ref).  Each subtype is defined by a particular choice
for the parametrization of the unary and pairwise parts.  At present the options
are:

* [`ALfull`](@ref): A model with type [`FullUnary`](@ref) as the unary part, and type
  [`FullPairwise`](@ref) as the pairwise part (parameters ``α, Λ``).
* [`ALsimple`](@ref): A model with type [`FullUnary`](@ref) as the unary part, and type
  [`SimplePairwise`](@ref) as the pairwise part (parameters ``α, λ``).
* [`ALRsimple`](@ref): A model with type [`LinPredUnary`](@ref) as the unary part, and type
  [`SimplePairwise`](@ref) as the pairwise part (parameters ``β, λ``).

The first two types above are mostly for research or exploration purposes.  Most users doing
data analysis will use the `ALRsimple` model.  

Each of the above types have various constructors defined.  For example, `ALRsimple(G, X)`
will create an `ALRsimple` model with graph `G` and predictor matrix `X`.  Type, e.g.,
`?ALRsimple` at the REPL to see the constructors.

Any of the above model types can be used with any of the supported forms of centering, and
with any desired coding.  Centering and coding can be set at the time of construction, or
the `centering` and `coding` fields of the type can be mutated to change the default
choices.

**2. Set parameters.**

Depending on the constructor used, the model just initialized will have either default
parameter values or user-specified parameter values.  Usually
it will be desired to choose some appropriate values from data.

* [`fit_ml!`](@ref) uses maximum likelihood to estimate the parameters.  It is only useful for
  cases where the number of vertices in the graph is small.
* [`fit_pl!`](@ref) uses pseudolikelihood to estimate the parameters.
* [`setparameters!`](@ref), [`setunaryparameters!`](@ref), and
  [`setpairwiseparameters!`](@ref) can be used to set the parameters of the model directly.
* [`getparameters`](@ref), [`getunaryparameters`](@ref), and
  [`getpairwiseparameters`](@ref) can be used to retrieve the parameter values.

Changing the parameters directly, through the fields of the model object, is
discouraged.  It is preferable for safety to use the above get and set functions.

**3. Inference and exploration.**

After parameter estimation, one typically wants to use the fitted model to answer
inference questions, make plots, and the so on.

For small-graph cases:

* [`fit_ml!`](@ref) returns p-values and 95% confidence intervals that can be used directly.
* [`fullPMF`](@ref), [`conditionalprobabilities`](@ref), [`marginalprobabilities`](@ref) can
  be used to get desired quantities from the fitted distribution.
* [`sample`](@ref) can be used to draw random samples from the fitted distribution.

For large-graph cases:

* If using [`fit_pl!`](@ref), argument `nboot` can be used to do inference by parametric
  bootstrap at the time of fitting.
* After fitting, `oneboot` and `addboot` can be used to create and add parametric bootstrap
  replicates after the fact.
* Sampling can be used to estimate desired quantities like marginal probabilities.  The
  [`sample`](@ref) function implements Gibbs sampling as well as several perfect sampling
  algorithms.

Estimation by `fit_ml!` or `fit_pl!` returns an object of type `ALfit`, which holds the
parameter estimates and other information.

Plotting can be done using standard Julia capabilities.  The [Examples](@ref) section
shows how to make a few relevant plots.

The [Examples](@ref) section demonstrates the usage of all of the above capabilities.