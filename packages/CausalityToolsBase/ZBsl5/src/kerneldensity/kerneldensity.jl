import Statistics: mean, std
import Distances: Metric, Chebyshev, evaluate
import NearestNeighbors: KDTree, inrange
import DelayEmbeddings: Dataset


abstract type Kernel end 
struct BoxKernel <: Kernel end
#struct GaussianKernel <: Kernel end 

export silverman_rule, kerneldensity, BoxKernel #, GaussianKernel

"""
    silverman_rule(pts)

Find the approximately optimal bandwidth for a kernel density estimate, 
assuming the density is Gaussian (Silverman, 1996).
"""
function silverman_rule(pts)
    n_pts = length(pts)
    dim = length(pts[1])
    # Average marginal standard deviation
    σs = zeros(Float64, dim)
    for i = 1:dim
        σs[i] = std([pt[i] for pt in pts])
    end
    σ = mean(σs)
    
    # Approximately optimal bandwidth
    σ*(4/(dim + 2))^(1/(dim + 4)) * n_pts^(-(1/(dim + 4)))
end

""" 
    scaling(kernel::Kernel, n_pts, h, dim)

Return the scaling factor for `kernel` for a given number 
of points `n_pts`, bandwidth `h` in dimension `dim`.
"""
function scaling end

#scaling(kernel::GaussianKernel, n_pts, h, dim) = 1/(h^dim) * (1/(pi^(dim/2)))
scaling(kernel::BoxKernel, n_pts, h) = 1/(2*n_pts*h)

""" 
     evaluate_kernel(kerneltype::Kernel, args...)

Evaluate the kernel function of type `kerneltype` with the provided `args`.

## Example 

- `evaluate_kernel(GaussianKernel(), d, σ` evaluates the Gaussian 
kernel for the distance `d` and average marginal standard deviation `σ`.
"""
function evaluate_kernel end 

# """
#     evaluate_kernel(GaussianKernel(), d, σ)

# Evaluate the Gaussian kernel for the distance `d` and average marginal 
# standard deviation `σ` 
# """
# evaluate_kernel(kerneltype::GaussianKernel, d, σ) = exp(-((d)/(2*σ^2)))

"""
    evaluate_kernel(BoxKernel(), idxs_pts_within_range)

Evaluate the the Box kernel by counting the number of points that 
fall within the range of a query point (the points falling inside 
a radius of `h` has been precomputed).
"""
function evaluate_kernel(kerneltype::BoxKernel, idxs_pts_within_range) 
    # The point itself is always included, so subtract 1
    length(idxs_pts_within_range) - 1
end

"""
    kerneldensity(pts, gridpts, kernel::BoxKernel; 
        h = silverman_rule(pts), 
        metric::Metric = Chebyshev(), 
        normalise = true) -> Vector{Float64}

Naive box kernel density estimator from [1].

# Arguments 

- **`pts`**: The points for which to evaluate the density.

- **`gridpts`**: A set of grid point on which to evaluate the density.

- **`kernel`**: A `Kernel` type. Defaults to `BoxKernel`. Can also be 
    `GaussianKernel`.

# Keyword arguments

- **`h`**: The bandwidth. Uses Silverman's rule to compute an optimal 
    bandwidth assuming a Gaussian density (note: we're not using
    a Gaussian kernel here, so might be off).

- **`gridpts`**: A set of grid point on which to evaluate the density.

- **`normalise`**: Normalise the density so that it sums to 1.

- **`metric`**: A instance of a valid metric from `Distances.jl` that is 
    nonnegative, symmetric and satisfies the triangle inequality. Defaults to 
    `metric = Chebyshev()`.

# Returns 

A density estimate for each grid point.


# References 

[1] [Steuer, R., Kurths, J., Daub, C.O., Weise, J. and Selbig, J., 2002. The mutual information: detecting and evaluating dependencies between variables. Bioinformatics, 18(suppl_2), pp.S231-S240](https://academic.oup.com/bioinformatics/article/18/suppl_2/S231/190783).

# Example 
```julia
using DynamicalSystems, CausalityToolsBase, Distributions 

# Create some example points from a multivariate normal distribution
d = MvNormal(rand(Uniform(-1, 1), 2), rand(Uniform(0.1, 0.9), 2))
pts = Dataset([rand(d) for i = 1:500])

# Evaulate the density at a subset of those points given all the points
gridpts = Dataset([SVector{2, Float64}(pt) for pt in pts[1:5:end]])

# Get normalised density 
kd_norm = kerneldensity(pts, gridpts, BoxKernel(), normalise = true);
kd_nonnorm = kerneldensity(pts, gridpts, BoxKernel(), normalise = false);

# Make sure the result sums to one of normalised and that it doesn't when not normalising
sum(kd_norm) ≈ 1
!(sum(kd_nonnorm) ≈ 1)

```

"""
function kerneldensity(pts, gridpts, kernel::BoxKernel; 
        h = silverman_rule(pts), 
        metric::Metric = Chebyshev(), 
        normalise = true)
    
    n_gridpts = length(gridpts)
    n_pts = length(pts)

    # We don't need to reorder the tree, because distances are irrelevant
    tree = KDTree(pts, metric)
        
    # Stores the distances to each gridpoint.
    dists = zeros(Float64, n_pts)

    # Stores the number of points within distance `h` to each grid point.
    fx = zeros(Float64, n_gridpts)
    
    for i = 1:n_gridpts 
        idxs_pts_withinrange_of_gridpt = inrange(tree, gridpts[i], h, false)
        fx[i] = evaluate_kernel(kernel, idxs_pts_withinrange_of_gridpt)
    end
    
    # Scaling
    fx .= scaling(kernel, n_pts, h) .* fx
    
    # Normalise distribution
    normalise ? fx .= fx ./ sum(fx) : fx
    
    return fx
end

# """
#     kerneldensity(pts, gridpts, kernel::GaussianKernel; 
#         h = silverman_rule(pts), metric::Metric = Euclidean(), 
#         leafsize::Int = 10, normalise = true)

# Naive kernel density estimator (Steuer et al., 2002).

# # Arguments 
# - **`pts`**: The points for which to evaluate the density.
# - **`gridpts`**: A set of grid point on which to evaluate the density.
# - **`estimator`**: A `GaussianKernel` instance indicating that we're
#     using a Gaussian kernel.

# # Keyword arguments
# - **`h`**: The bandwidth. Uses Silverman's rule to compute an optimal 
#     bandwidth assuming a Gaussian density (which is used).
# - **`gridpts`**: A set of grid point on which to evaluate the density.
# - **`normalise`**: Normalise the density so that it sums to 1.
# - **`metric`**: A valid metric from `Distances.jl` that is nonnegative,
#     symmetric and satisfies the triangle inequality.


# ## References 
# Steuer, R., Kurths, J., Daub, C.O., Weise, J. and Selbig, J., 2002. The mutual information: 
# detecting and evaluating dependencies between variables. Bioinformatics, 18(suppl_2), pp.S231-S240.
# """
# function kerneldensity(pts, gridpts, kernel::GaussianKernel; 
#         h = silverman_rule(pts), metric::Metric = Chebyshev(), 
#         leafsize::Int = 30, normalise = true)
    
#     T = eltype(pts[1])
#     dim = length(pts[1])
#     n_gridpts = length(gridpts)
#     n_pts = length(pts)

#     # We don't need to reorder the tree, because distances are irrelevant
#     tree = KDTree(pts, metric)
        
#     # Stores the distances to each gridpoint.
#     dists = zeros(Float64, n_pts)

#     # Stores the number of points within distance `h` to each grid point.
#     fx = zeros(Float64, n_gridpts)
    
#     @inbounds for i = 1:n_gridpts 
#         fx_i = 0.0
#         for j = 1:n_pts
#             dist = evaluate(metric, gridpts[i], pts[j])
#             fx_i += evaluate_kernel(kernel, dist, h)
#         end
       
#         fx[i] = fx_i
#     end
    
#     # Scaling
#     @inbounds fx .= scaling(kernel, n_pts, h, dim) .* fx
    
#     # Normalise distribution
#     @inbounds normalise ? fx .= fx ./ sum(fx) : fx

#     return fx
# end