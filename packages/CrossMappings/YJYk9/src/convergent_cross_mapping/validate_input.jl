function validate_libsize(libsize, driver, dim, τ, ν, replace)
    n_available_pts = length(driver) - dim*τ - abs(ν)
    if libsize > n_available_pts
        if replace
            @warn "libsize = $libsize > n_available_pts = $n_available_pts. Sampling with replacement."
        else
            throw(DomainError(libsize, "libsize = $libsize > n_available_pts = $n_available_pts. Reduce `libsize` (preferably to something much smaller than `n_available_pts = $n_available_pts`) or enable sampling with replacement."))
        end
    end
end


function validate_embedding!(embedding, jitter)
    maxval = abs(maximum(embedding))
    unique_pts = unique(embedding, dims = 2)
    if size(unique_pts, 2) < size(embedding, 2)
        @warn "Not all embedding points are unique. Jittering coordinates by `rand(Uniform(-$jitter*maximum(embedding), $jitter*maximum(embedding)))`"

        for i in 1:length(embedding)
            embedding[i] += rand(Uniform(-jitter*maxval, jitter*maxval))
        end
    end
end


function validate_exclusion_radius!(exclusion_radius, points_available)
    if exclusion_radius < 0
        throw(DomainError(exclusion_radius, "`exclusion_radius=$exclusion_radius`. Must be ≧ 0."))
    end
    if exclusion_radius >= ceil(Int, 0.5*points_available)
        throw(DomainError(exclusion_radius, "`exclusion_radius=$exclusion_radius >= ceil(Int, 0.5*(length(response) - dim*τ))=$points_available`. Please reduce `exclusion_radius`."))
    end
end


function validate_embedding_params(dim, τ, points_available)
    if dim == 1
        @warn "`dim=$dim`, but must be at least 2 to construct an embedding."
    end
    if dim <= 0
        throw(DomainError(dim, "`dim=$dim` must be at least 2 to construct an embedding."))
    end
    if τ == 0
        @warn "`τ=$τ` does not produce a delay embedding!"
    end
    if τ < 0
        @warn "`τ=$τ` is negative. The cross mapping algorithm is implemented assuming τ is positive."
    end
    if dim*τ >= ceil(Int, 0.5*points_available)
        throw(DomainError(exclusion_radius, "`exclusion_radius=$exclusion_radius >= ceil(Int, 0.5*(length(response) - dim*τ))=$points_available`. Please reduce `exclusion_radius`."))
    end
end


function validate_surr(which_is_surr, surr_func)
    if surr_func ∉ [TimeseriesSurrogates.randomshuffle,
                    TimeseriesSurrogates.randomphases,
                    TimeseriesSurrogates.randomamplitudes,
                    TimeseriesSurrogates.aaft,
                    TimeseriesSurrogates.iaaft]
        throw(DomainError(surr_func, "surr_func = $surr_func is not a valid surrogate function from TimeseriesSurrogates.jl." ))
    end

    if which_is_surr ∉ [:response, :driver, :none, :both]
        throw(DomainError(which_is_surr, "which_is_surr = $which_is_surr is invalid. Must be either :response, :driver, :none or :both"))
    end
end


function validate_uncertainty_measure(uncertainty_measure)
    if uncertainty_measure ∉ [:quantile, :std, :none]
        throw(DomainError(uncertainty_measure, "uncertainty_measure = $uncertainty_measure is invalid. Must be either :quantile, :std or :none."))
    end
end


function validate_average_measure(average_measure)
    if average_measure ∉ [:mean, :median, :none]
        throw(DomainError(average_measure, "average_measure = $average_measure is invalid. Must be either :median, :mean or :none."))
    end
end


function validate_output_selection(average_measure, uncertainty_measure, summarise)
    if ((average_measure, uncertainty_measure) == (:none, :none)) && summarise
        throw(ErrorException("Setting both average_measure and uncertainty_measure to :none while summarise = true will not produce output."))
    end
end

export
validate_surr,
validate_libsize,
validate_embedding!,
validate_embedding_params,
validate_exclusion_radius!,
validate_uncertainty_measure,
validate_average_measure,
validate_output_selection
