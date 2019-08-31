using BayesianIntegral
using Distributions: Normal, MvNormal, pdf
using LinearAlgebra: diagm, Symmetric
using Statistics
using HCubature: hcubature
using Sobol
using Random
standard_normal = Normal(0.0,1.0)

# Integral of gaussian distribution should be 1.
samples = 29
dims = 1
p(x) = 1.0
X = Array{Float64,2}(undef,samples,1)
X[:,1] =  collect(-2.0:(4.0/(samples-1)):2.0) #
y = p.(X)[:,1]
cov_func_parameters = gaussian_kernel_hyperparameters(1.0, repeat([2.0] , outer = dims))
prob_means = [0.0]
covar = Array{Float64,2}(undef,1,1)
covar[1,1] = 1.0
covar = Symmetric(covar)
noise = 0.2
integ = bayesian_integral_gaussian_exponential(X, y, prob_means, covar, cov_func_parameters, noise)
(integ.expectation - 1) < 0.01

# Integral in two dimensions
samples = 25
dims = 2
p(x) = 1.0
s = SobolSeq(dims)
X = convert( Array{Float64}, hcat([next!(s, repeat([0.5] , outer = dims)     ) for i = 1:samples]...)' )
y = repeat([1.0] , outer = samples)
cov_func_parameters = gaussian_kernel_hyperparameters(1.0, repeat([10.0] , outer = dims))
prob_means = repeat([0.0] , outer = dims)
covar = Symmetric(diagm(0 => ones(dims)))
noise = 0.2
integ = bayesian_integral_gaussian_exponential(X, y, prob_means, covar, cov_func_parameters, noise)
(integ.expectation - 1) < 0.02

# In ten dimensinos
samples = 50
dims = 10
p(x) = 1.0
s = SobolSeq(dims)
X = convert(Array{Float64}, hcat([next!(s, repeat([0.5] , outer = dims)     ) for i = 1:samples]...)')
y = repeat([1.0] , outer = samples)
cov_func_parameters = gaussian_kernel_hyperparameters(1.0, repeat([20.0] , outer = dims))
prob_means = repeat([0.0] , outer = dims)
covar = Symmetric(diagm(0 => ones(dims)))
noise = 0.2
integ = bayesian_integral_gaussian_exponential(X, y, prob_means, covar, cov_func_parameters, noise)
(integ.expectation - 1) < 0.02

##### More complex cases #####
# Now looking at a more complex one.
function f(x::Array{Float64,1})
    ndims = length(x)
    total = 12.0
    for i in 1:ndims
        total = total - x[i]^2 - 2*x[i]
    end
    return total
end
function fp(x::Array{Float64,1})
    ndim = length(x)
    if ndim == 1
        return f(x) * pdf.(Ref(standard_normal), x)
    else
        dist = MvNormal(zeros(ndim),diagm(0 => ones(ndim)))
        return f(x) * pdf(dist, x)
    end
end
function fp(x)
    global counter = counter + 1
    flipped = convert(Array{Float64,1},x)
    return fp(flipped)
end

dims = 1
bayesianAttempts = 10

function compare_for_f(dims::Int, bayesianAttempts::Int = 0, paths::Int = 0;  seed::Int = 1988)
    Random.seed!(1234)
    # Traditional
    global counter = 0
    lims = 3.0
    maxIter = 5000
    numerical_val, numerical_err = hcubature(x -> fp(x), repeat([-lims], outer = dims), repeat([lims], outer = dims); maxevals = maxIter)
    cont = counter

    # Kriging
    if bayesianAttempts < 1
        samples = cont
    else
        samples = bayesianAttempts
    end
    s = SobolSeq(dims)
    X = (hcat([next!(s, repeat([0.5] , outer = dims)     ) for i = 1:samples]...)' .- 0.5) .* (lims*2.0)
    y = Array{Float64,1}(undef, samples)
    for r in 1:samples
        y[r] = f(X[r,:])
    end
    noise = 0.05
    cov_func_parameters = gaussian_kernel_hyperparameters(1.0, repeat([1.0] , outer = dims))
    prob_means = repeat([0.0], outer = dims)
    covar = Symmetric(diagm(0 => ones(dims)))
    bayesian_val, bayesian_err = bayesian_integral_gaussian_exponential(X, y, prob_means, covar, cov_func_parameters, noise)

    # Kriging with new weights
    steps = 2000
    batch_size = convert(Int, floor( samples / 4 ) )
    step_multiple = 0.02
    seed = 1988
    K_mat = K_matrix(X, gaussian_kernel, cov_func_parameters, noise)
    like = log_likelihood(y, K_mat)
    n_cov_func_parameters = calibrate_by_ML_with_SGD(X, y, cov_func_parameters, steps, batch_size, step_multiple, noise, seed)
    K_mat = K_matrix(X, gaussian_kernel, n_cov_func_parameters, noise)
    nlike = log_likelihood(y, K_mat)
    nbayesian_val, nbayesian_err = bayesian_integral_gaussian_exponential(X, y , prob_means, covar, n_cov_func_parameters, noise)


    # Kriging with new weights and RProp
    params = RProp_params(1.01,0.99,0.2,5.0,0.5)
    MaxIter = 2000
    nn_cov_func_parameters = calibrate_by_ML_with_Rprop(X, y, cov_func_parameters, MaxIter, noise, params)
    K_mat = K_matrix(X, gaussian_kernel, n_cov_func_parameters, noise)
    rproplikelihood = log_likelihood(y, K_mat)
    rpropnbayesian_val, rpropnbayesian_err = bayesian_integral_gaussian_exponential(X, y , prob_means, covar, nn_cov_func_parameters, noise)

    # MC Integration
    if paths < 1
        paths = cont
    end
    dist = MvNormal(zeros(dims),diagm(0 => ones(dims)))
    Xs = transpose(convert(Matrix{Float64}, rand(dist, paths)))
    ys = Array{Float64,1}(undef, paths)
    for r in 1:paths
        ys[r] = f(Xs[r,:])
    end
    MC_integral = mean(ys)
    MC_err = std(ys) / sqrt(paths)

    print("For ", dims, " dimensions \n")
    print("    Bayesian    Integral is               ", bayesian_val       , " with error ", bayesian_err       ," and ", samples , " evaluations \n")
    print("    Calibrated Bayesian Integral is       ", nbayesian_val      , " with error ", nbayesian_err      ," and ", samples , " evaluations \n")
    print("    Rprop Calibrated Bayesian Integral is ", rpropnbayesian_val , " with error ", rpropnbayesian_err ," and ", samples , " evaluations \n")
    print("    Traditional Integral is               ", numerical_val[1]   , " with error ", numerical_err[1]   ," and ", cont    , " evaluations \n")
    print("    MC          Integral is               ", MC_integral        , " with error ", MC_err             ," and ", paths   , " evaluations \n")
    print("        Likelihood was ", like   , " and calibrated is ", nlike, " and Rprop calibrated is ", rproplikelihood  ,"\n")
    print("        weights became ", n_cov_func_parameters.w_0   , " and  ", n_cov_func_parameters.w_i, " with SGD \n")
    print("        weights became ", nn_cov_func_parameters.w_0    , " and  ", nn_cov_func_parameters.w_i, " with RProp \n")
    return (bayesian_val = bayesian_val, bayesian_err = bayesian_err, samples = samples, traditional_value = numerical_val[1], traditional_error = numerical_err, traditional_evals = cont, MC_integral = MC_integral, MC_err = MC_err, paths = paths)
end

f1_results = compare_for_f(1, 100)
abs(f1_results.bayesian_val - f1_results.MC_integral) < 0.01
f2_results = compare_for_f(2, 300)
abs(f2_results.bayesian_val - f2_results.MC_integral) < 0.11
#f10_results = compare_for_f(10, 200, 20000)
#f20_results = compare_for_f(20, 2000, 2000)
