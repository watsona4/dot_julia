# Design of the Package

The package was created to satisfy the following goals:

* To make it easy for researchers to compare the different variants of the AL/ALR models
  (different combinations of coding and centering), to test the claim that the symmetric
  model is superior to the other alternatives.
* To facilitate analysis of real-world data sets with correlated binary responses, hopefully
  with good performance.
* To create a code base that is fairly easy to extend as new extensions on AL/ALR models
  are developed.

These goals guided the design of the package, which is briefly described here.

## Type Hierarchy

Three abstract types are used to define a type hierarchy that will hopefully allow the
codebase to be easily extensible.  The type `AbstractAutologisticModel` is the top-level
type for AL/ALR models.  Most of the functions for computing with AL/ALR models are
defined to operate on this type, so that concrete subtypes should not have to re-implement
them.

The `AbstractAutologisticModel` interface requires subtypes to have a number of fields.  Two
of them are `unary` and `pairwise`, which must inherit from `AbstractUnaryParameter` and
`AbstractPairwiseParameter`, respectively.  These two abstract types define interfaces for
the unary and pairwise parts of the model. Concrete subtypes of these two types represent
different ways of parametrizing the unary and pairwise terms.

For example, the most useful ALR model implemented in the package is the model with a
linear predictor as the unary parameter
(``\boldsymbol{\alpha}=\mathbf{X}\boldsymbol{\beta}``), and the "simple pairwise" assumption
for the pairwise term (``\boldsymbol{\Lambda} = \lambda\mathbf{A}``).  This model has type
`ALRsimple`, with unary type `LinPredUnary` and pairwise type `SimplePairwise`.  A model
of this type can be instantiated with any desired coding, and different forms of centering.

With this design, adding a new type of AL/ALR model with a different parametrization
involves

* Creating `NewUnaryType <: AbstractUnaryParameter`
* Creating `NewPairwiseType <: AbstractPairwiseParameter`
* Creating `NewModelType <: AbstractAutologisticModel`, including instances of the two new
  types as its `unary` and `pairwise` fields.

This process should not be too cumbersome, as the unary and pairwise interfaces mainly
require implementing indexing and show methods. Sampling, computation of probabilities,
handling of centering, etc., is handled by fallback methods in the abstract types.

## Important Notes

Here are a few points to be aware of in using the package.  For this list, let `M` be a
an AL or ALR model type.

* Responses are stored in `M.responses` as arrays of type `Bool`.
* The coding is stored separately in `M.coding`.  Not storing the responses as a numeric
  type makes it easier to maintain consistency when working with models that might have
  different codings.
* Use functions `makebool` and `makecoded` to get to and from coded/boolean forms of the
  responses.
* Parameters are always represented as **vectors** of `Float64`, with unary parameters first
  and pairwise parameters at the end.  
* The above is true even when the parameter only has length 1, as with the `SimplePairwise`
  type.  So you need to use square brackets, as in `setparameters!(MyPairwise, [1.0])`, when
  setting the parameters in that case.
* The package uses [LightGraphs.jl](https://github.com/JuliaGraphs/LightGraphs.jl) for
  representing graphs, and [Optim.jl](https://github.com/JuliaNLSolvers/Optim.jl) for
  optimization.

## Random Sampling

Random sampling is particularly important for AL/ALR models, because (except for very small
models), it isn't possible to evaluate the normalized PMF.  Monte Carlow approaches to
Estimation and inference are common with these models.  

The `sample` function is provided for random sampling from an AL/ALR model.  The function
takes a `method` argument, which specifies the sampling algorithm to use. Use
`?SamplingMethods` at the REPL to see the available options.  

The default sampling method is Gibbs sampling, since that method will always work.  But
there are several perfect (exact) sampling options provided in the package.  Depending on
the model's parameters, perfect sampling will either work just fine, or be prohibitively
slow.  It is recommended to use one of the perfect sampling methods if possible. The
different sampling algorithms can be compared for efficiency in particular cases.