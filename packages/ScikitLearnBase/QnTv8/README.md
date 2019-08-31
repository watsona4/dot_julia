ScikitLearnBase.jl
------------

This package exposes the scikit-learn interface. Packages that implement this
interface can be used in conjunction with [ScikitLearn.jl](https://github.com/cstjean/ScikitLearn.jl) (pipelines, cross-validation, hyperparameter tuning, ...)

This is an intentionally slim package (~100 LOC, no dependencies). That way,
ML libraries can `import ScikitLearnBase` without dragging along all of
`ScikitLearn`'s dependencies.

Overview
-----

The docs contain [an overview of the API](http://scikitlearnjl.readthedocs.org/en/latest/api/) and a [more thorough specification](docs/API.md).

There are two implementation strategies for an existing machine learning package:

 - *Create a new type that wraps the existing type*. The new type can usually be written entirely on top of the existing codebase (i.e. without modifying it). This gives more implementation freedom, and a more consistent interface amongst the various ScikitLearn.jl models. Here's an [example](https://github.com/cstjean/DecisionTree.jl/blob/2722950c8f0c5e5c62204364308e28d4123383cb/src/scikitlearnAPI.jl) from DecisionTree.jl
 - *Use the existing type*. This requires less code, and is usually better when the model type already contains the hyperparameters / fitting arguments.

Example
-----

For models with simple hyperparameters, it boils down to this:

```julia
import ScikitLearnBase

type NaiveBayes
    # The model hyperparameters (not learned from data)
    bias::Float64

    # The parameters learned from data
    counts::Matrix{Int}
    
    # A constructor that accepts the hyperparameters as keyword arguments
    # with sensible defaults
    NaiveBayes(; bias=0.0f0) = new(bias)
end

# This will define `clone`, `set_params!` and `get_params` for the model
ScikitLearnBase.@declare_hyperparameters(NaiveBayes, [:bias])

# NaiveBayes is a classifier
ScikitLearnBase.is_classifier(::NaiveBayes) = true   # not required for transformers

function ScikitLearnBase.fit!(model::NaiveBayes, X, y)
    # X should be of size (n_sample, n_feature)
    .... # modify model.counts here
    return model
end

function ScikitLearnBase.predict(model::NaiveBayes, X)
    .... # returns a vector of predicted classes here
end
```

Models with more complex hyperparameter specifications should implement `clone`,
`get_params` and `set_params!` explicitly instead of using
`@declare_hyperparameters`. 

More examples of PRs that implement the interface: [GaussianMixtures.jl](https://github.com/davidavdav/GaussianMixtures.jl/pull/18/files), [GaussianProcesses.jl](https://github.com/STOR-i/GaussianProcesses.jl/pull/17/files), [DecisionTree.jl](https://github.com/bensadeghi/DecisionTree.jl/pull/29/files), [LowRankModels.jl](https://github.com/madeleineudell/LowRankModels.jl/pull/56/files)

Note: if the model performs unsupervised learning, implement `transform`
instead of `predict`.

Once your library implements the API, [file an
issue/PR](https://github.com/cstjean/ScikitLearn.jl/issues) to add it to
the [list of models](http://scikitlearnjl.readthedocs.io/en/latest/models/#julia-models).
