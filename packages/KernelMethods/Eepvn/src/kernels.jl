module Kernels

export gaussian_kernel, sigmoid_kernel, cauchy_kernel, linear_kernel

"""
Creates a Gaussian kernel with the given distance function and `sigma` value
"""
function gaussian_kernel(dist, sigma=1.0)
    sigma2 = sigma * 2
    function fun(obj, ref)::Float64
        d = dist(obj, ref)
        (d == 0 || sigma == 0) && return 1.0
        exp(-d / sigma2)
    end

    fun
end

"""
Creates a sigmoid kernel with the given `sigma` value and distance function
"""
function sigmoid_kernel(dist, sigma=1.0)
    sqrtsigma = sqrt(sigma)
    function fun(obj, ref)::Float64
        x = dist(obj, ref)
        2 * sqrtsigma / (1 + exp(-x))
    end

    fun
end

"""
Creates a Cauchy's kernel with the given `sigma` value and distance function
"""
function cauchy_kernel(dist, sigma=1.0)
    sqsigma = sigma^2
    function fun(obj, ref)::Float64
        x = dist(obj, ref)
        (x == 0 || sqsigma == 0) && return 1.0
        1 / (1 + x^2 / sqsigma)
    end

    fun
end

"""
Creates a tanh kernel with the given `sigma` value and distance function
"""
function tanh_kernel(dist, sigma=1.0)
    function fun(obj, ref)::Float64
        x = dist(obj, ref)
        (exp(x-sigma) - exp(-x+sigma)) / (exp(x-sigma) + exp(-x+sigma))
    end

    fun
end

"""
Creates a linear kernel with the given distance function and `sigma` slope 
"""
function linear_kernel(dist, sigma=1.0)
    function fun(obj, ref)::Float64
        dist(obj, ref) * sigma
    end

    fun
end

end
