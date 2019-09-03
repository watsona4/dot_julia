module StochasticIntegrals

using DataFrames
using Dates
using Distributions: Normal, quantile
using LinearAlgebra: Symmetric, cholesky, inv, det, LowerTriangular, diag
using MultivariateFunctions
using Random
using Sobol: SobolSeq, next!
using FixedPointAcceleration

include("1_main_functions.jl")
export ItoIntegral, get_volatility, get_variance, get_covariance, get_correlation, ItoSet, CovarianceAtDate
export get_normal_draws, get_sobol_normal_draws, get_zero_draws, pdf, make_covariance, log_likelihood, brownians_in_use
include("2_data_conversions.jl")
export to_draws, to_dataframe, to_array
include("3_getConfidenceHypercube.jl")
export get_confidence_hypercube

end
