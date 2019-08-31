using StateSpaceReconstruction
include("validate_input.jl")

"""
    predict_point!(predictions, i, driver_values, u, w, dists, dim)

The prediction part of the convergent cross mapping algorithm.

## Algorithm

Consider the point in the delay embedding of `response` point with
time index `i`. Denote the time indices of its nearest
neighbors ``t_1, t_2, \\ldots, t_{dim+1}``. Denote the scalar values
of `driver` at those time indices ``y_1, y_2, \\ldots, y_{dim+1}``.

Given `distances` ``d_1, d_2, \\ldots, d_{dim+1}`` from the `i`-th
point to its nearest neighbors, we compute the weights `w` from
the cross mapping algorithm ([Sugihara et al, 2012; supplementary
material, page 4](http://science.sciencemag.org/content/sci/suppl/2012/09/19/science.1227079.DC1/Sugihara.SM.pdf)). The weights `w` and coefficients `u` are stored in
pre-allocated vectors.

A prediction for the observation with time index `i` in the `driver`
timeseries, call it ``\\hat{y}(i)``, is computed as the sum

```math
\\hat{y}(i) = \\sum_{j=1}^{dim+1} w_j y_j.
```

We store the prediction ``\\hat{y}(i)`` in position `i` of the pre-allocated vector
`predictions`.


## Arguments
- **`predictions`**: A pre-allocated vector in which to store the
    prediction for the scalar value of the `driver` series.
- **`i`**: The time index of the point of the `driver` series being
    predicted. The prediction is stored in `predictions[i]`.
- **`driver_values`**: Let ``t_1, t_2, \\ldots, t_{dim + 1}`` be
    the time indices of
    the nearest neighbors to the delay embedding point with time
    index `i`. `driver_values` contains the scalar values of the
    `driver` series at those time indices.
- **`u`**: A pre-allocated vector of length `dim + 1` that holds the
    normalisation coefficients for computing the weights in the
    cross mapping algorithm.
- **`w`**: A pre-allocated vector of length `dim + 1` that holds
    the computed weights for the cross mapping algorithm.
- **`dists`**: The distances from delay embedding point with time index
    `i` to its `dim + 1` nearest neighbors, in order of increasing
    distances.
- **`dim`**: The dimension of the delay embedding.

## References
Sugihara, George, et al. "Detecting causality in complex ecosystems."
Science (2012): 1227079.
[http://science.sciencemag.org/content/early/2012/09/19/science.1227079](http://science.sciencemag.org/content/early/2012/09/19/science.1227079)

"""
function predict_point!(predictions, i, driver_values, u, w, distances, dim)
    if distances[1] == 0
        @warn "The first distance is zero. Will yield division by zero"
    end
    for j in 1:(dim + 1)
        u[j] = exp(-(distances[j]/distances[1]))
    end
    # The `predictions` vector is pre-allocated and `predictions[i]` may
    # have a nonzero value if it has been visited in a previous iteration.
    # Reset, so that we are always starting the prediction from zero.
    predictions[i] = 0.0
    for j in 1:(dim + 1)
        #w[j] = u[j] / sum(u)
        predictions[i] =+ sum((u[j] / sum(u)) .* driver_values)
    end
end


function find_nearest!(nearest_idxs, nearest_dists, i, idxs, dists, dim, exclusion_radius)
    if (2 * exclusion_radius + 2 + dim) > length(idxs[1])
       throw(DomainError(exclusion_radius, "Too few points can be selected from `idxs=$idxs` with `dim=$dim` and `exclusion_radius=$exclusion_radius`."))
    end

    N = length(nearest_idxs)

    for k = 1:N
        # If exclusion_radius == 0, then skip the first
        # point, because it is the distance to itself.
        if exclusion_radius == 0
            for j = 1:(dim + 1)
                nearest_idxs[k][j] = idxs[k][j + 1]
                nearest_dists[k][j] = dists[k][j + 1]
            end
        # Otherwise, find the nearest neighbors outside
        # the temporal exclusion radius.
        else
            points_found = 0
            # assume we have already checked a point, so that
            # we skip the first neighbor (which is the point
            # itself).
            points_tried = 1
            while points_found < (dim + 1)
                if (idxs[k][points_tried + 1] < (i - exclusion_radius) ||
                    idxs[k][points_tried + 1] > (i + exclusion_radius))
                    nearest_idxs[k][points_found + 1] = idxs[k][points_tried + 1]
                    nearest_dists[k][points_found + 1] = dists[k][points_tried + 1]
                    points_found += 1
                end
                points_tried += 1
            end
        end
    end
end


"""
    crossmap(driver, response;
        dim::Int = 3,
        τ::Int = 1,
        libsize::Int = 10,
        replace::Bool = false,
        n_reps::Int = 100,
        surr_func::Function = randomshuffle,
        which_is_surr::Symbol = :none,
        exclusion_radius::Int = 0,
        tree_type = NearestNeighbors.KDTree,
        distance_metric = Distances.Euclidean(),
        correspondence_measure = StatsBase.cor,
        ν::Int = 0)

## Algorithm
Compute the cross mapping between a `driver` series and a `response` series.

## Arguments
- **`driver`**: The data series representing the putative driver process.
- **`response`**: The data series representing the putative response process.
- **`dim`**: The dimension of the state space reconstruction (delay embedding)
    constructed from the `response` series. Default is `dim = 3`.
- **`τ`**: The embedding lag for the delay embedding constructed from `response`.
    Default is `τ = 1`.
- **`ν`**: The prediction lag to use when predicting scalar values of `driver`
    fromthe delay embedding of `response`.
    `ν > 0` are forward lags (causal; `driver`'s past influences `response`'s future),
    and `ν < 0` are backwards lags (non-causal; `driver`'s' future influences
    `response`'s past). Adjust the prediction lag if you
    want to performed lagged ccm
    [(Ye et al., 2015)](https://www.nature.com/articles/srep14750).
    Default is `ν = 0`, as in
    [Sugihara et al. (2012)](http://science.sciencemag.org/content/early/2012/09/19/science.1227079).
    *Note: The sign of the lag `ν` is organized to conform with the conventions in
    [TransferEntropy.jl](), and is opposite to the convention used in the
    [`rEDM`](https://cran.r-project.org/web/packages/rEDM/index.html) package
    ([Ye et al., 2016](https://cran.r-project.org/web/packages/rEDM/index.html)).*
- **`libsize`**: Among how many delay embedding points should we sample time indices
    and look for nearest neighbours at each cross mapping realization (of which there
    are `n_reps`)?
- **`n_reps`**: The number of times we draw a library of `libsize` points from the
    delay embedding of `response` and try to predict `driver` values. Equivalently,
    how many times do we cross map for this value of `libsize`?
    Default is `n_reps = 100`.
- **`replace`**: Sample delay embedding points with replacement? Default is `replace = true`.
- **`exclusion_radius`**: How many temporal neighbors of the delay embedding
    point `response_embedding(t)` to exclude when searching for neighbors to
    determine weights for predicting the scalar point `driver(t + ν)`.
    Default is `exclusion_radius = 0`.
- **`which_is_surr`**: Which data series should be replaced by a surrogate
    realization of the type given by `surr_type`? Must be one of the
    following: `:response`, `:driver`, `:none`, `:both`.
    Default is `:none`.
- **`surr_func`**: A valid surrogate function from TimeseriesSurrogates.jl.
- **`tree_type`**: The type of tree to build when looking for nearest neighbors.
    Must be a tree type from NearestNeighbors.jl. For now, this is either
    `BruteTree`, `KDTree` or `BallTree`.
- **`distance_metric`**: An instance of a `Metric` from Distances.jl. `BallTree` and `BruteTree` work with any `Metric`.
    `KDTree` only works with the axis aligned metrics `Euclidean`, `Chebyshev`,
    `Minkowski` and `Cityblock`. Default is `metric = Euclidean()` *(note the instantiation of the metric)*.
- **`correspondence_measure`**: The function that computes the correspondence
    between actual values of `driver` and predicted values. Can be any
    function returning a similarity measure between two vectors of values.
    Default is `correspondence_measure = StatsBase.cor`, which returns values on ``[-1, 1]``.
    In this case, any negative values are usually filtered out (interpreted as zero coupling) and
    a value of ``1`` means perfect prediction.
    [Sugihara et al. (2012)](http://science.sciencemag.org/content/early/2012/09/19/science.1227079)
    also proposes to use the root mean square deviation, for which a value of ``0`` would
    be perfect prediction.

## References
Sugihara, George, et al. "Detecting causality in complex ecosystems."
Science (2012): 1227079.
[http://science.sciencemag.org/content/early/2012/09/19/science.1227079](http://science.sciencemag.org/content/early/2012/09/19/science.1227079)

Ye, Hao, et al. "Distinguishing time-delayed causal interactions using convergent cross mapping." Scientific Reports 5 (2015): 14750.
[https://www.nature.com/articles/srep14750](https://www.nature.com/articles/srep14750)

Ye, H., et al. "rEDM: Applications of empirical dynamic modeling from time series." R Package Version 0.4 7 (2016).
[https://cran.r-project.org/web/packages/rEDM/index.html](https://cran.r-project.org/web/packages/rEDM/index.html)
"""
function crossmap(driver, response;
            dim::Int = 3,
            τ::Int = 1,
            ν::Int = 0,
            libsize::Int = length(driver) - dim*τ - abs(ν),
            n_reps::Int = 100,
            replace::Bool = true,
            exclusion_radius::Int = 0,
            jitter::Float64 = 1e-3,
            which_is_surr::Symbol = :none,
            surr_func::Function = randomshuffle,
            tree_type = NearestNeighbors.KDTree,
            distance_metric = Distances.Euclidean(),
            correspondence_measure = StatsBase.cor)

    points_available = length(response) - dim*τ
    validate_exclusion_radius!(exclusion_radius, points_available)
    validate_embedding_params(dim, τ, points_available)
    validate_surr(which_is_surr, surr_func)
    validate_libsize(libsize, driver, dim, τ, ν, replace)

    if which_is_surr == :response
        response = surr_func(response)
    elseif which_is_surr == :driver
        driver = surr_func(driver)
    elseif which_is_surr == :both
        driver = surr_func(driver)
        response = surr_func(response)
    end

    ######################################################################
    # Embedding and the nearest neighbor search.
    # ----------------------------------------------------------
    # All searches are done before the cross mapping repetitions,
    # because this is computationally cheaper for all but the
    # smallest library sizes and number of repetitions.
    ######################################################################
    embedding_lags = collect(1:-τ:-(τ*dim - 1))
    embedding = StateSpaceReconstruction.Embeddings.embed([response], [1 for i in 1:dim], embedding_lags).points
    n_embedding_pts = size(embedding, 2)

    validate_embedding!(embedding, jitter)
    tree = tree_type(embedding, distance_metric)

    idxs, dists = knn(tree, embedding, dim + 2 + 2*exclusion_radius + 1, true)
    nearest_idxs = [zeros(Int32, dim + 1) for i = 1:n_embedding_pts]
    nearest_dists = [zeros(Float64, dim + 1) for i = 1:n_embedding_pts]

    for i in 1:n_embedding_pts
        find_nearest!(nearest_idxs, nearest_dists, i, idxs, dists, dim, exclusion_radius)
    end

    ######################################################################
    # Cross mapping
    ######################################################################
    # Pre-allocate vectors to hold weights and coefficients, as well as
    # the predictions, for the prediction part of the algorithm.
    u = Vector{Float64}(undef, dim + 1)
    w = Vector{Float64}(undef, dim + 1)
    predictions =  zeros(Float64, libsize)

    # Pre-allocate vector to hold the time indices of the library points
    # we select at each cross map repetition (it is from these points
    # predictions are made).
    point_idxs = zeros(Int32, libsize)

    # Pre-allocate vector to hold the correspondences between actual
    # and predicted values of the driver time series.
    correspondence = zeros(Float64, n_reps)

    for k in 1:n_reps
        if ν >= 0
            sample!((1 + ν):n_embedding_pts, point_idxs, replace = replace)
        else
            sample!(1:(n_embedding_pts - abs(ν)), point_idxs, replace = replace)
        end

        # For every point selected at this repetition, make a prediction.
        @inbounds for i in 1:length(point_idxs)
            idx = point_idxs[i]
            predict_point!(predictions, i, driver[nearest_idxs[idx]], u, w, nearest_dists[idx], dim)
        end

        correspondence[k] = correspondence_measure(predictions, driver[point_idxs .- ν])
    end

    return correspondence
end

export
predict_point!,
find_nearest!,
crossmap
