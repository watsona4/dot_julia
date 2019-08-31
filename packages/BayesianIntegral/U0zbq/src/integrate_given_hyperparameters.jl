
abstract type kernel_hyperparameters end
struct gaussian_kernel_hyperparameters <: kernel_hyperparameters
    w_0::Float64
    w_i::Array{Float64,1}
end


"""
    gaussian_kernel(x1::Array{Float64,1}, x2::Array{Float64,1}, cov_func_parameters::gaussian_kernel_hyperparameters)
Returns a covariance estimated with a gaussian kernel.
"""
function gaussian_kernel(x1::Array{Float64,1}, x2::Array{Float64,1}, cov_func_parameters::gaussian_kernel_hyperparameters)
    return cov_func_parameters.w_0 * exp(-0.5 * sum(((x1 .- x2) ./ cov_func_parameters.w_i) .^ 2))
end

"""
    marginal_gaussian_kernel(x1::Array{Float64}, x2::Array{Float64}, cov_func_parameters::gaussian_kernel_hyperparameters)
Returns a covariance estimated with a gaussian kernel. Also returns the marginal covariances (how does each covariance change by bumping each hyperparameter).
"""
function marginal_gaussian_kernel(x1::Array{Float64,1}, x2::Array{Float64,1}, cov_func_parameters::gaussian_kernel_hyperparameters)
    # This should take in two points in N-dimensional space and a hyperparameter vector and output the covariance between them.
    # In addition it should output a matrix with all of the marginal values.
    w_i = cov_func_parameters.w_i
    dim_of_cov_func_parameters = length(w_i) + 1
    properval = gaussian_kernel(x1, x2, cov_func_parameters)
    marginal_vals = Array{Float64,1}(undef, dim_of_cov_func_parameters)
    marginal_vals[1]  = properval/cov_func_parameters.w_0
    for i in 2:(dim_of_cov_func_parameters)
        marginal_vals[i] =  ((x1[i-1] - x2[i-1])^2 / w_i[i-1]^3 ) * properval
    end
    return (cov = properval, marginal_covariances = marginal_vals)
end

"""
    K_matrix(X::Array{Float64,2}, cov_func::Function, cov_func_parameters::gaussian_kernel_hyperparameters, noise::Float64 = 0.0)
Returns a K_matrix together with marginal K matrices (marginal over each hyperparameter). THe cov_func should be a function
with a signature like that of gaussian_kernel.
"""
function K_matrix(X::Array{Float64,2}, cov_func::Function, cov_func_parameters::gaussian_kernel_hyperparameters, noise::Float64 = 0.0)
    NoObs = size(X)[1]
    KK = diagm(0 => ones(NoObs))
    for r in 1:NoObs
        for c in (r+1):NoObs
            KK[r,c] = cov_func(X[r,:], X[c,:], cov_func_parameters)
        end
    end
    noise_matrix = noise * diagm(0 => ones(NoObs))
    return Symmetric(KK + noise_matrix)
end

"""
    K_matrix_with_marginals(X::Array{Float64,2}, cov_func::Function, cov_func_parameters::gaussian_kernel_hyperparameters, noise::Float64 = 0.0)
Returns a K_matrix together with marginal K matrices (marginal over each hyperparameter)
"""
function K_matrix_with_marginals(X::Array{Float64,2}, cov_func::Function, cov_func_parameters::gaussian_kernel_hyperparameters, noise::Float64 = 0.0)
    NoObs = size(X)[1]
    Ndims =  size(X)[2]
    number_of_marginal_matrices = length(cov_func_parameters.w_i) + 1
    covar_matrix = diagm(0 => ones(NoObs))
    mats = Array{Float64,3}(undef, NoObs,NoObs,number_of_marginal_matrices)
    for m in 1:number_of_marginal_matrices
        mats[:,:,m] =  convert(Matrix{Float64}, zeros(Float64,NoObs,NoObs))
    end
    for r in 1:NoObs
        for c in (r+1):NoObs
            results, marginals = cov_func(X[r,:], X[c,:], cov_func_parameters)
            covar_matrix[r,c] = results
            for m in 1:number_of_marginal_matrices
                mats[r,c,m] = marginals[m]
            end
        end
    end
    cov_mat = Symmetric(covar_matrix + noise * diagm(0 => ones(NoObs)) )
    for m in 1:number_of_marginal_matrices
        mats[:,:,m] =  Symmetric(mats[:,:,m])
    end
    return (k_mat = cov_mat,  marginal_K_matrices = mats)
end

"""
    log_likelihood( y::Array{Float64,1},  K::Symmetric{Float64,Array{Float64,2}}; invK::Symmetric{Float64,Array{Float64,2}} = inv(K), determinant = det(K))
The log likelihood of a kriging model with values y and covariances K. invK and the determinant can be fed in as well to prevent additional operations.
Note that the normalising constant is excluded from the log likelihood here because it is not relevent for optimising hyperparameters.
"""
function log_likelihood(y::Array{Float64,1},  K::Symmetric{Float64,Array{Float64,2}}; invK::Symmetric{Float64,Array{Float64,2}} = inv(K), determinant = det(K))
    return -0.5 * transpose(y) * invK * y - 0.5 * log(determinant)
end

"""
    marginal_likelihood_gaussian_derivatives(X::Array{Float64,2}, y::Array{Float64,1}, w_0::Float64, w_i::Array{Float64,1}, noise::Float64 = 0.0)
The marginal likelihoods (along each parameter) of a kriging model are returned.
In addition the K matrix and the inverse K matrix are returned (to allow programers to use them as generated here and no redo them).
"""
function marginal_likelihood_gaussian_derivatives(X::Array{Float64,2}, y::Array{Float64,1}, cov_func_parameters::gaussian_kernel_hyperparameters, noise::Float64 = 0.0)
     w_0 = cov_func_parameters.w_0
     w_i = cov_func_parameters.w_i
    # From eqn 5.9 of Rasmussen and Williams
    K, marginal_covariances = K_matrix_with_marginals(X, marginal_gaussian_kernel, gaussian_kernel_hyperparameters(w_0,w_i), noise)
    invK = inv(K)
    alpha = invK * y
    alpha_alphaT__m_Kinv = alpha * transpose(alpha) - invK
    n_hyperparameters = size(marginal_covariances)[3]
    marginal_likelihoods = Array{Float64,1}(undef, n_hyperparameters)
    for i in 1:n_hyperparameters
        marginal_likelihoods[i] = 0.5 * tr(alpha_alphaT__m_Kinv * marginal_covariances[:,:,i])
    end
    return (marginal_likelihoods = marginal_likelihoods, k_mat = K, inv_K_matrix = invK)
end

"""
    bayesian_integral_gaussian_exponential( X::Array{Float64,2}, f::Array{Float64,1} , prob_means::Array{Float64} , covar::Symmetric{Float64,Array{Float64,2}}, w_0::Float64, w_i::Array{Float64}, noise::Float64 = 0.0)
Returns the expectation and variance of the integral of a kriging model defined by the evaluations specified by X and f, the hyperparameters  w_0 & w_i and the noise value.
The integration performed is: int_{x in X} f(x) p(x) dx
Where f(x) is the function which is approximated in the kriging map by an exponential covariance function and p(x) is
the pdf which is multivariate gaussian.
"""
function bayesian_integral_gaussian_exponential(X::Array{Float64,2}, f::Array{Float64,1} , prob_means::Array{Float64,1}, covar::Symmetric{Float64,Array{Float64,2}}, cov_func_parameters::gaussian_kernel_hyperparameters, noise::Float64 = 0.0 )
    ndim = length(cov_func_parameters.w_i)
    nobs = size(X)[1]
    A = diagm(0 => cov_func_parameters.w_i.^2)
    K = K_matrix(X, BayesianIntegral.gaussian_kernel, cov_func_parameters, noise)
    invA = inv(A)
    invK = inv(K)
    AplusBinv = inv(A + covar)

    multipl = cov_func_parameters.w_0 * LinearAlgebra.det(invA * covar + diagm(0 => ones(ndim)))^(-0.5)
    z = Array{Float64,1}(undef, nobs)
    for i in 1:nobs
        amb = X[i,:] - prob_means
        z[i] = multipl * exp(-0.5 * transpose(amb) * AplusBinv * amb)[1,1]
    end
    expectation = transpose(z) * invK * f
    var = cov_func_parameters.w_0 * det(2 * invA * covar +diagm(0 => ones(ndim)))^(-0.5) - transpose(z) * invK * z
    return (expectation = expectation, variance = var)
end
