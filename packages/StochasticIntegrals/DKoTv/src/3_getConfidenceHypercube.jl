function _one_iterate(cutoff_multiplier::Float64, target::Float64, draws::Array{Float64,2}, covar_matrix::Symmetric, tuning_parameter::Float64)
    cutoffs = cutoff_multiplier .* sqrt.(diag(covar_matrix))
    number_of_draws = size(draws)[1]
    in_confidence_area = 0
    for i in 1:number_of_draws
        in_confidence_area += all(abs.(draws[i,:]) .< cutoffs)
    end
    mass_in_area = in_confidence_area/number_of_draws
    confidence_gap = target - mass_in_area
    return cutoff_multiplier + confidence_gap * tuning_parameter
end
function _sobols(chol, num::Int, sob_seq::SobolSeq)
    dims = size(chol)[1]
    array = Array{Float64,2}(undef, num, dims)
    for i in 1:num
        sobs = next!(sob_seq)
        normal_draw = quantile.(Ref(Normal()), sobs)
        scaled_draw = chol * normal_draw
        array[i,:] = scaled_draw
    end
    return array
end

"""
    get_confidence_hypercube(covar::CovarianceAtDate, confidence_level::Float64, data::Array{Float64,2}; tuning_parameter::Float64 = 1.0)
This returns the endpoints of a hypercube that contains confidence_level% of the dataset. For instance
"""
function get_confidence_hypercube(covar::CovarianceAtDate, confidence_level::Float64, data::Array{Float64,2}; tuning_parameter::Float64 = 1.0)
    # Using a univariate guess as we can get these pretty cheaply.
    guess = quantile(Normal(), 0.5*(1+confidence_level))
    FP = fixed_point(x -> _one_iterate.(x, Ref(confidence_level), Ref(data), Ref(covar.covariance_), Ref(tuning_parameter)), [guess])
    cutoff_multiplier = FP.FixedPoint_[1]
    cutoffs = vcat(zip(-cutoff_multiplier .* sqrt.(diag(covar.covariance_)) , cutoff_multiplier .* sqrt.(diag(covar.covariance_)))...)
    return Dict{Symbol,Tuple{Float64,Float64}}(covar.covariance_labels_ .=> cutoffs)
end

function get_confidence_hypercube(covar::CovarianceAtDate, confidence_level::Float64, num::Int; tuning_parameter::Float64 = 1.0)
    dims = length(covar.covariance_labels_)
    data = _sobols(covar.chol_, num, SobolSeq(dims))
    return get_confidence_hypercube(covar, confidence_level, data; tuning_parameter = tuning_parameter)
end
