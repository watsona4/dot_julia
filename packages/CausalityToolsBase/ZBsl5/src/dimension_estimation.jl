import DelayEmbeddings.estimate_delay
import DelayEmbeddings.estimate_dimension

"""
    optimal_delay(v; method = "mi_min")

Estimate the optimal embedding lag for `v`. 

# Keyword arguments

- **`method`**: Either "fnn" (Kennel's false nearest neighbors method). 
    Default is `mi_min`.

- **`τs`**: The lags over which to estimate the embedding lag. Defaults to 10% of the 
    length of the time series.

# Example 

```julia 
using CausalityToolsBase 

ts = diff(rand(100))
optimal_delay(ts)
optimal_delay(ts, method = "mi_min")
optimal_delay(ts, method = "mi_min", τs = 1:10)
```
"""
function optimal_delay(v; method = "mi_min", τs = 1:1:min(ceil(Int, length(v)/15), 100))
    τ = estimate_delay(v, method, τs)
end

"""
    optimal_dimension(v, τ; dims = 2:8; method = "fnn"; kwargs...)

Estimate the optimal embedding dimension for `v`.

# Arguments

- **`v`**: The data series for which to estimate the embedding dimension.

- **`τ`**: The embedding lag.

- **`dims`**: Dimensions to probe for the optimal dimension.

# Keyword arguments

- **`method`**: Either "fnn" (Kennel's false nearest neighbors method),
    "afnn" (Cao's average false nearest neighbors method) or "f1nn" (Krakovská's
    false first nearest neighbors method). See the source code for
    `DelayEmbeddings.estimate_dimension` for more details.

- **`rtol`**: Tolerance `rtol` in Kennel's algorithms. See [`DelayEmbeddings.fnn`](https://github.com/JuliaDynamics/DelayEmbeddings.jl/blob/master/src/estimate_dimension.jl)
     source code for more details.
    
- **`atol`**: Tolerance `rtol` in Kennel's algorithms. See [`DelayEmbeddings.fnn`](https://github.com/JuliaDynamics/DelayEmbeddings.jl/blob/master/src/estimate_dimension.jl)
    source code for more details.

# Example

```julia 
using CausalityToolsBase 
        
ts = diff(rand(1000))
optimal_dimension(ts)
optimal_dimension(ts, dims = 3:5)
optimal_dimension(ts, method = "afnn")
optimal_dimension(ts, method = "fnn")
optimal_dimension(ts, method = "f1nn")
```
"""
function optimal_dimension(v, τ, method = "f1nn"; dims = 2:8, kwargs...)
    # The embedding dimension should be the dimension returned by
    # estimate_dimension plus one (see DelayEmbeddings.jl source code).
    if method == "fnn"
        γs = estimate_dimension(v, τ, method = "f1nn", dims[1:(end - 1)]; kwargs...)
        # Kennel's false nearest neighbor method should drop to zero near the
        # optimal value of γ, so find the minimal value of γ for the dims
        # we've probed.
        dim = findmin(γs)[2] + 1
        return dim
    elseif method == "afnn"
        γs = estimate_dimension(v, τ, dims[1:(end - 1)], method = "afnn"; kwargs...)
        # Cao's averaged false nearest neighbors method saturates around 1.0
        # near the optimal value of γ, so find the γ closest to 1.0 for the
        # dims we've probed.
        dim = findmin(1.0 .- γs)[2] + 1
        return dim
    elseif method == "f1nn"
        γs = estimate_dimension(v, τ, dims[1:(end - 1)], method = "f1nn"; kwargs...)
        # Krakovská's false first nearest neighbors method drops to zero near
        # the optimal value of γ, so find the minimal value of γ for the dims
        # we've probed.
        dim = findmin(γs)[2] + 1
        return dim
    else
        throw(DomainError("method=$method for estimating dimension is not valid."))
    end
end


"""
    optimal_dimension(v; dims = 2:8,
        method_dimension = "fnn", method_delay = "mi_min")

Estimate the optimal embedding dimension for `v` by first estimating
the optimal lag, then using that lag to estimate the dimension.

## Arguments
- **`v`**: The data series for which to estimate the embedding dimension.
- **`dims`**: The dimensions to try.
- **`method_delay`**: The method for determining the optimal lag.
"""
function optimal_dimension(v; method = "f1nn",      
        dims = 2:8, 
        method_delay = "mi_min", 
        τs = 1:1:min(ceil(Int, length(v)/10), min(ceil(Int, length(v)/2), 100))
    )
    τ = optimal_delay(v, method = method_delay, τs = τs)
    optimal_dimension(v, τ, method)
end

export optimal_delay, optimal_dimension