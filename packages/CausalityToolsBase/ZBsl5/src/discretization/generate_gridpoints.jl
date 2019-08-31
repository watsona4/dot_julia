import Interpolations: GridType, OnGrid, OnCell

"""
    OnPoints

A grid type indicating that the grid should be represented by a set of points.
"""
struct OnPoints <: GridType end

"""
    generate_gridpoints(axisminima, stepsizes, n_intervals_eachaxis, 
        grid::GridType = OnGrid())

Return a set of points forming a grid over the hyperrectangular box 
spanned by

-  `(axisminima, axisminima .+ (n_intervals_eachaxis .* stepsizes)` if 
    `grid = OnGrid()`, and

-  `(axisminima, axisminima .+ ((n_intervals_eachaxis .+ 1) .* stepsizes)` if 
    `grid = OnCell()`,

where the minima along each coordinate axis (`axisminima`), the `stepsizes` along
each axis, and the set of intervals (`n_intervals_per_axis`) indicating how many 
equal-length intervals each axis should be divided into.

If `grid = OnGrid()`, then the bin origins are taken as the grid points. 
If `grid = OnCell()`, then one additional interval is added and the grid is shifted half
a bin outside the extrema along each axis, so that the grid points lie at the center of 
the grid cells.
"""
function generate_gridpoints(axisminima, stepsizes, n_intervals_eachaxis, 
        grid::GridType = OnGrid())

    D = length(axisminima)
    gridpoints = SVector{D, Float64}[]

    if grid == OnGrid() 
        extra_int = 1
    elseif grid == OnCell()
        extra_int = 2
    else
        throw(ArgumentError("method $method not valid. Must be either `OnGrid` or `OnCell`."))
    end
        
    sizehint!(gridpoints, prod(n_intervals_eachaxis .+ extra_int))
    v = zeros(Float64, D)
    n_origins_generated = 0
    counter = 0
    for I in Iterators.product([1:i for i in n_intervals_eachaxis .+ extra_int]...,)
        counter =+ 1
        v = zeros(Float64, D)

        for dim in 1:D
            v[dim] = axisminima[dim] + stepsizes[dim]*(I[dim] - 1) 
        end
        
        if grid == OnCell()
            push!(gridpoints, SVector{D, Float64}(v .- stepsizes ./ 2))
        elseif grid == OnGrid()
            push!(gridpoints, SVector{D, Float64}(v))
        end
    end

    return gridpoints
end


"""
    generate_gridpoints(points, binning_scheme::RectangularBinning, 
        grid::GridType = OnGrid())

Return a set of points forming a rectangular grid covering a 
hyperrectangular box specified  by the `binning_scheme` and `grid` type. 
Provided a suitable binning scheme is given, this grid will provide a 
covering of `points`. See the documentation for `RectangularBinning` for 
more details. 

# Arguments 

- **`points`**: A vector of points or a `Dataset` instance. 

- **`binning_scheme`**: A `RectangularBinning` instance. See docs for `RectangularBinning`
    for more details.

- **`grid`**: A `GridType` instance. The grid follows the same convention 
    as in Interpolations.jl. Valid choices are `OnGrid()` (uses the bin 
    origins as the grid points), and `OnCell()`, which adds an additional 
    interval along each axis, shifts the grid half a bin outside the 
    extrema along each axis and retursn the centers of the resulting 
    grid cells.

# Examples 

For example,

```julia 
using CausalityToolsBase, DelayEmbeddings

pts = Dataset([rand(3) for i = 1:100])
generate_gridpoints(pts, RectangularBinning(10), OnGrid()
```

generates a rectangular grid covering the range of `pts` constructed 
by subdividing each coordinate axis into 10 equal-length intervals. Next,

```julia 
using CausalityToolsBase, DelayEmbeddings

pts = Dataset([rand(3) for i = 1:100])
generate_gridpoints(pts, RectangularBinning(10), OnCell()
```

will do the same, but adds another interval (11 in total), shifts the 
entire hypercube so that the minima and maxima along each axis lie 
half a bin outside the original extrema, then returns the centers of 
the grid cells.
"""
function generate_gridpoints(points, binning_scheme::RectangularBinning, 
        grid::GridType = OnGrid())
    
    D = length(points[1])
    axisminima, edgelengths = get_minima_and_edgelengths(points, binning_scheme)
    
    if binning_scheme.ϵ isa Tuple{Vector{Tuple{Float64, Float64}}, Int}
        n_intervals = binning_scheme.ϵ[2]
        return generate_gridpoints(axisminima, edgelengths, [n_intervals for i = 1:D], grid)
        
    elseif binning_scheme.ϵ isa Int 
        n_intervals = binning_scheme.ϵ
        return generate_gridpoints(axisminima, edgelengths, [n_intervals for i = 1:D], grid)
        
    elseif binning_scheme.ϵ isa Vector{Int} 
        return generate_gridpoints(axisminima, edgelengths, binning_scheme.ϵ, grid)
                
    elseif binning_scheme.ϵ isa Float64  || binning_scheme.ϵ isa Vector{Float64}
        axismaxima = get_maxima(points)
        n_intervals = ceil.(Int, (axismaxima - axisminima) ./ edgelengths)
        
        return generate_gridpoints(axisminima, edgelengths, n_intervals, grid)
    end
end

export generate_gridpoints, OnCell, OnGrid, OnPoints