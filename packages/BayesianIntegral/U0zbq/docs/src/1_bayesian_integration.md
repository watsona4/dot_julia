# 1.0 Bayesian Integration

This package implements Bayesian Integration as described  by Rasmussen & Ghahramani (2003) and before that by O'Hagan (1991). These both use Kriging techniques to map out a function. The function is then integrated using this kriging map together with a multivariate Gaussian distribution gives a mass at each point in the function.

At present on an exponential kernel is supported and only a multivariate Gaussian distribution for assigning mass to various points in the function. Thus the bayesian\_integral\_gaussian\_exponential function is the only integration function in the package.
The exponential kernel used is:

$$\text{Cov}(f(x^p), f(x^q))=w_0e^{-\frac{1}{2}(\sum_{i=1}^d\frac{x^p_i - x_i^q}{w_i})^2}$$

Where $$d$$ is the dimensionality of the space the points $$x^p$$ and $$x^q$$ are defined in. $$w_0$$ and $$w_i$$ are hyperparameters which need to be input. This is done in the gaussian\_kernel\_hyperparameters structure. These hyperparameters can be trained with the functions in the next section of the documentation. For simplicity however we have all parameters being 1.0 in the example below:
```
using BayesianIntegral
using Sobol
samples = 25
dims = 2
p(x) = 1.0
s = SobolSeq(dims) # We use Sobol numbers to choose where to sample but we could choose any points.
X = convert( Array{Float64}, hcat([next!(s, repeat([0.5] , outer = dims)     ) for i = 1:samples]...)' )
function func(X::Array{Float64,1})
    return sum(X) - prod(X)
end
y = Array{Float64,1}(undef,samples)
for i in 1:samples
    y[i] = func(X[i,:])
end
# We need hyperparameters which describe what covariance exists in function values across every dimension.
cov_func_parameters = gaussian_kernel_hyperparameters(1.0, repeat([10.0] , outer = dims))
# Now we create a vector of means and a covariance matrix for the multivariate normal distribution describing the
# probability mass at each point in the function.
prob_means = repeat([0.0] , outer = dims)
covar = Symmetric(diagm(0 => ones(dims)))
# Some noise can be added to the function values. If a function is deterministic then no noise exists but a small
# amount can avoid issues with numerical imprecision.
noise = 0.001
# Now finding the integral
integ = bayesian_integral_gaussian_exponential(X, y, prob_means, covar, cov_func_parameters, noise)
```
We get a bayesian integral of $$N(0.308, 0.0004)$$ in terms of expectation, variance.
