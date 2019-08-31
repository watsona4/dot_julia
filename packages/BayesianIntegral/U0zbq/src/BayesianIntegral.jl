module BayesianIntegral

using LinearAlgebra
using Random

include("integrate_given_hyperparameters.jl")
export gaussian_kernel, marginal_gaussian_kernel, K_matrix
export gaussian_kernel_hyperparameters, bayesian_integral_gaussian_exponential
export marginal_likelihood_gaussian_derivatives, log_likelihood
include("calibrate_weights.jl")
export calibrate_by_ML_with_SGD, RProp_params, calibrate_by_ML_with_Rprop

end
