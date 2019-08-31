using ScikitLearnBase
using Test
using Statistics

################################################################################
# We implement NaiveBayes

mutable struct NaiveBayes
    # The model hyperparameters (not learned from data)
    bias::Float64

    # The parameters learned from data
    counts::Matrix{Int}
    class_counts::Vector{Int}

    # A constructor that accepts the hyperparameters as keyword arguments
    # with sensible defaults
    NaiveBayes(; bias=0.0f0) = new(bias)
end

# This will define `clone`, `set_params!` and `get_params` for the model
@declare_hyperparameters(NaiveBayes, [:bias])

# NaiveBayes is a classifier
is_classifier(::NaiveBayes) = true

function fit!(nb::NaiveBayes, X::Matrix{Bool}, Y::Vector{Int})
    n_class = length(unique(Y))
    # Start at one (default bias)
    nb.counts = ones(Int, size(X, 2), n_class)
    for (row_no, y) in enumerate(Y)
        for (i, x) in enumerate(X[row_no, :])
            nb.counts[i, y] += x
        end
    end
    nb.class_counts = [sum(Y .== i) for i in 1:n_class]
    nb
end


# P(X_i|C_k)
probs_X_C(nb::NaiveBayes) = nb.counts ./ sum(nb.counts, dims=1)
prior_C(nb::NaiveBayes) = nb.class_counts ./ sum(nb.class_counts)

function predict_proba(nb::NaiveBayes, X::Matrix{Bool})
    p_mat = log.(probs_X_C(nb))
    pnot_mat = log.(1.0 .- probs_X_C(nb))
    prior_mat = log.(prior_C(nb))
    # .! is not valid prior to Julia 0.6
    out = exp.((X * p_mat + 0 * map((!), X) * pnot_mat) .+ prior_mat')
    out ./ sum(out, dims=2) # normalize
end

################################################################################
# Test that it works. I've compared the results with ScikitLearn's version.

X = [true false
     true false
     false false
     true true]
Y = [1, 1, 2, 1]

nb = fit!(NaiveBayes(), X, Y)

# Check that the results are the same as scikit-learn's
@test isapprox(mean(predict_proba(nb, X)[:,1]), 0.76931818181818)
