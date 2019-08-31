__precompile__()

module ScikitLearnBase

using Random
using LinearAlgebra  # necessary for `dot`
using Statistics     # for `mean`

macro declare_api(api_functions...)
    esc(:(begin
        $([Expr(:function, f) for f in api_functions]...)
        # Expr(:export, f) necessary in Julia 0.3
        $([Expr(:export, f) for f in api_functions]...)
        const api = [$([Expr(:quote, x) for x in api_functions]...)]
    end))
end
# These are the functions that can be implemented by estimators/transformers.
# See http://scikitlearnjl.readthedocs.org/en/latest/api/
@declare_api(fit!, partial_fit!, transform, fit_transform!, fit_predict!,
             predict, predict_proba, predict_log_proba, predict_dist,
             score_samples, sample,
             score, decision_function, clone, set_params!,
             get_params, is_classifier, is_pairwise,
             get_feature_names, get_classes, get_components,
             inverse_transform)

export BaseEstimator, BaseClassifier, BaseRegressor, declare_hyperparameters,
       @declare_hyperparameters

# Ideally, all scikit-learn estimators would inherit from BaseEstimator, but
# it's hard to ask library writers to do that given single-inheritance, so the
# API doesn't rely on it.
abstract type BaseEstimator end
abstract type BaseClassifier <: BaseEstimator end
abstract type BaseRegressor <: BaseEstimator end

is_classifier(::BaseClassifier) = true
is_classifier(::BaseRegressor) = false

# This hasn't been used so far, but it seems like it should be useful at some
# point, and it doesn't cost much.
implements_scikitlearn_api(estimator) = false   # global default
implements_scikitlearn_api(estimator::BaseEstimator) = true

################################################################################
# These functions are useful for defining estimators that do not themselves
# contain other estimators

function simple_get_params(estimator, param_names::Vector)
    # Not written as a comprehension for 0.3/0.5 compatibility
    di = Dict{Symbol, Any}()
    for name::Symbol in param_names di[name] = getfield(estimator, name) end
    di
end

function simple_set_params!(estimator::T, params; param_names=nothing) where {T}
    for (k, v) in params
        if param_names !== nothing && !(k in param_names)
            throw(ArgumentError("An estimator of type $T was passed the invalid hyper-parameter $k. Valid hyper-parameters: $param_names"))
        end
        setfield!(estimator, k, v)
    end
    estimator
end

# See also https://github.com/JuliaLang/julia/pull/15546
# `clone_param` allows me to easily customize certain special values, like RNG
clone_param(v::Any) = v # fall-back
clone_param(rng::Random.MersenneTwister) = deepcopy(rng) # issue #15698. Solved in 0.5
function simple_clone(estimator::T) where {T}
    kw_params = Dict{Symbol, Any}()
    # cloning the values is scikit-learn's default behaviour. It's ok?
    for (k, v) in get_params(estimator) kw_params[k] = clone_param(v) end
    return T(; kw_params...)
end

function declare_hyperparameters(estimator_type::Type{T},
                                    params::Vector{Symbol}) where {T}
    warn("declare_hyperparameters(...) is deprecated. Use @declare_hyperparameters(...) instead.")
    @eval begin
        ScikitLearnBase.get_params(estimator::$(estimator_type); deep=true) =
            simple_get_params(estimator, $params)
        ScikitLearnBase.set_params!(estimator::$(estimator_type);
                                    new_params...) =
            simple_set_params!(estimator, new_params; param_names=$params)
        ScikitLearnBase.clone(estimator::$(estimator_type)) =
            simple_clone(estimator)
    end
end

"""
    @declare_hyperparameters(estimator_type::Type{T}, params::Vector{Symbol})

This top-level macro helps to implement the scikit-learn protocol for simple
estimators (those that do not contain other estimators). It will define
`set_params!`, `get_params` and `clone` for `::estimator_type`.
It is called at the top-level. Example:

    @declare_hyperparameters(GaussianProcess, [:regularization_strength])

Each parameter should be a field of `estimator_type`.

Most models should call this function. The only exception are models that
contain other models. They should implement `get_params` and `set_params!`
manually. """
macro declare_hyperparameters(estimator_type, params)
    :(begin
        $ScikitLearnBase.get_params(estimator::$(esc(estimator_type));
                                    deep=true) =
            simple_get_params(estimator, $(esc(params)))
        $ScikitLearnBase.set_params!(estimator::$(esc(estimator_type));
                                    new_params...) =
            simple_set_params!(estimator, new_params;param_names=$(esc(params)))
        $ScikitLearnBase.clone(estimator::$(esc(estimator_type))) =
            simple_clone(estimator)
    end)
end

################################################################################
# Standard scoring functions (those are good defaults)

# Helper
function weighted_sum(sample_score, sample_weight; normalize=false)
    if sample_weight === nothing
        return normalize ? mean(sample_score) : sum(sample_score)
    else
        s = dot(sample_score, sample_weight)
        return normalize ? (s / sum(sample_weight)) : s
    end
end

# scikit-learn's version is fancier, but I would rather KISS for now
classifier_accuracy_score(y_true::Vector, y_pred::Vector;
                          normalize=true, sample_weight=nothing) =
    weighted_sum(y_true.==y_pred, sample_weight, normalize=normalize)

mean_squared_error(y_true::AbstractVector, y_pred::AbstractVector;
                   sample_weight=nothing) =
    weighted_sum((y_true - y_pred) .^ 2, sample_weight; normalize=true)

mse_score(y_true, y_pred; sample_weight=nothing) =
    -mean_squared_error(y_true, y_pred; sample_weight=sample_weight)

score(clf::BaseClassifier, X, y_true; sample_weight=nothing) =
    classifier_accuracy_score(y_true, predict(clf, X);
                              sample_weight=sample_weight)
score(reg::BaseRegressor, X, y_true; sample_weight=nothing) =
    mse_score(y_true, predict(reg, X); sample_weight=sample_weight)


################################################################################
# Defaults

fit_transform!(estimator::BaseEstimator, X, y=nothing; fit_kwargs...) =
    transform(fit!(estimator, X, y; fit_kwargs...), X)
fit_predict!(estimator::BaseEstimator, X, y=nothing; fit_kwargs...) =
    predict(fit!(estimator, X, y; fit_kwargs...), X)

end
