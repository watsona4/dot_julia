struct ConsistentSampling <: BootstrapSampling
    nrun::Int
end

"""
    bootstrap(statistic, data, sampling::ConsistentSampling[;
              rng::AbstractRNG = Random.GLOBAL_RNG])

Obtain non-parametric bootstrap samples of `statistic` from the `data` set of predictions
and corresponding labels using consistency resampling, i.e., resampling of the labels.

Optionally you can specify a random number generator `rng` that is used for resampling
the data.
"""
function Bootstrap.bootstrap(statistic,
                             data::Tuple{<:AbstractMatrix{<:Real},<:AbstractVector{<:Integer}},
                             sampling::ConsistentSampling;
                             rng::AbstractRNG = Random.GLOBAL_RNG)
    # check arguments
    predictions, labels = data
    nclasses, nsamples = size(predictions)
    nsamples == length(labels) ||
        throw(DimensionMismatch("number of predictions and labels must be equal"))

    # use same heuristic as StatsBase to decide whether to sample predictions
    # directly or to build an alias table
    # TODO: needs proper benchmarking
    if nsamples < 40
        bootstrap_direct(statistic, data, sampling; rng = rng)
    else
        t = nsamples < 500 ? 64 : 32
        if nclasses < t
            bootstrap_direct(statistic, data, sampling; rng = rng)
        else
            bootstrap_alias(statistic, data, sampling; rng = rng)
        end
    end
end

# sample labels directly (without alias table)
function bootstrap_direct(statistic,
                          data::Tuple{<:AbstractMatrix{<:Real},<:AbstractVector{<:Integer}},
                          sampling::ConsistentSampling;
                          rng::AbstractRNG = Random.GLOBAL_RNG)
    # check arguments
    predictions, labels = data
    nclasses, nsamples = size(predictions)
    nsamples == length(labels) ||
        throw(DimensionMismatch("number of predictions and labels must be equal"))

    # evaluate statistic
    t0 = tx(statistic(data))

    # create caches
    resampled_predictions = similar(predictions)
    resampled_labels = similar(labels)
    resampled_data = (resampled_predictions, resampled_labels)

    # create sampler
    sp = Random.RangeGenerator(Base.OneTo(nsamples))

    # create output
    m = nrun(sampling)
    t1 = zeros_tuple(typeof(t0), m)

    # for each resampling step
    @inbounds for i in 1:m
        # resample data
        for j in 1:nsamples
            # resample predictions
            idx = rand(rng, sp)
            for k in axes(predictions, 1)
                resampled_predictions[k, j] = predictions[k, idx]
            end

            # resample labels
            p = rand(rng)
            cw = resampled_predictions[1, j]
            label = 1
            while cw < p && label < nclasses
                label += 1
                cw += resampled_predictions[label, j]
            end
            resampled_labels[j] = label
        end

        # evaluate statistic
        for (j, t) in enumerate(tx(statistic(resampled_data)))
            t1[j][i] = t
        end
    end

    NonParametricBootstrapSample(t0, t1, statistic, data, sampling)
end

# sample labels with alias table
function bootstrap_alias(statistic,
                         data::Tuple{<:AbstractMatrix{<:Real},<:AbstractVector{<:Integer}},
                         sampling::ConsistentSampling;
                         rng::AbstractRNG = Random.GLOBAL_RNG)
    # check arguments
    predictions, labels = data
    nclasses, nsamples = size(predictions)
    nsamples == length(labels) ||
        throw(DimensionMismatch("number of predictions and labels must be equal"))

    # evaluate statistic
    t0 = tx(statistic(data))

    # create alias table
    accept = [Vector{Float64}(undef, nclasses) for _ in 1:nsamples]
    alias = [Vector{Int}(undef, nclasses) for _ in 1:nsamples]
    @inbounds for i in axes(predictions, 2)
        StatsBase.make_alias_table!(view(predictions, :, i), 1.0, accept[i], alias[i])
    end

    # create sampler of labels
    splabels = Random.RangeGenerator(Base.OneTo(nclasses))

    # create caches
    resampled_predictions = similar(predictions)
    resampled_labels = similar(labels)
    resampled_data = (resampled_predictions, resampled_labels)

    # create sampler
    sp = Random.RangeGenerator(Base.OneTo(nsamples))

    # create output
    m = nrun(sampling)
    t1 = zeros_tuple(typeof(t0), m)

    # for each resampling step
    @inbounds for i in 1:m
        # resample data
        for j in 1:nsamples
            # resample predictions
            idx = rand(rng, sp)
            for k in axes(predictions, 1)
                resampled_predictions[k, j] = predictions[k, idx]
            end

            # resample labels
            l = rand(rng, splabels)
            resampled_labels[j] = rand(rng) < accept[j][l] ? l : alias[j][l]
        end

        # evaluate statistic
        for (j, t) in enumerate(tx(statistic(resampled_data)))
            t1[j][i] = t
        end
    end

    NonParametricBootstrapSample(t0, t1, statistic, data, sampling)
end

@deprecate bootstrap(statistic, predictions::AbstractMatrix{<:Real}, labels::AbstractVector{<:Integer}, sampling::ConsistentSampling) bootstrap(statistic, (predictions, labels), sampling)
@deprecate bootstrap(statistic, rng::AbstractRNG, predictions::AbstractMatrix{<:Real}, labels::AbstractVector{<:Integer}, sampling::ConsistentSampling) bootstrap(statistic, (predictions, labels), sampling; rng = rng)
