import DelayEmbeddings: Dataset, minima, maxima
import StaticArrays: SVector, MVector

export 
get_minima_and_edgelengths, 
get_edgelengths, 
get_minima,
get_maxima,
get_minmaxes


"""
    get_minima(pts) -> SVector

Return the minima along each axis of the dataset `pts`.
"""
function get_minima end

"""
    get_maxima(pts) -> SVector

Return the maxima along each axis of the dataset `pts`.
"""
function get_maxima end

"""
    get_minmaxes(pts) -> Tuple{Vector{Float}, Vector{Float}}

Return a vector of tuples containing axis-wise (minimum, maximum) values.
"""
function get_minmaxes end

function get_minima(pts::Dataset)
    minima(pts)
end

function get_minima(pts::Vector{T}) where {T <: Union{SVector, MVector, Vector}}
    minima(Dataset(pts))
end

function get_maxima(pts::Dataset)
    maxima(pts)
end

function get_maxima(pts::Vector{T}) where {T <: Union{SVector, MVector, Vector}}
    maxima(Dataset(pts))
end


function get_minmaxes(pts::Dataset)
    mini, maxi = minima(pts), maxima(pts)
    minmaxes = [(mini[i], maxi[i]) for i = 1:length(mini)]
end

function get_minmaxes(pts::Vector{T}) where {T <: Union{SVector, MVector, Vector}}
    get_minmaxes(Dataset(pts))
end


"""
    get_minima_and_edgelengths(points, 
        binning_scheme::RectangularBinning) -> (Vector{Float}, Vector{Float})

Find the minima along each axis of the embedding, and computes appropriate
edge lengths given a rectangular `binning_scheme`, which provide instructions on how to 
grid the space. Assumes the input is a vector of points.

See documentation for [`RectangularBinning`](@ref) for details on the 
binning scheme.

# Example 

```julia
using DynamicalSystems, CausalityToolsBase
pts = Dataset([rand(4) for i = 1:1000])

get_minima_and_edgelengths(pts, RectangularBinning(0.6))
get_minima_and_edgelengths(pts, RectangularBinning([0.5, 0.3, 0.4, 0.4]))
get_minima_and_edgelengths(pts, RectangularBinning(10))
get_minima_and_edgelengths(pts, RectangularBinning([10, 8, 5, 4]))
```
"""
function get_minima_and_edgelengths(points, binning_scheme::RectangularBinning)
    ϵ = binning_scheme.ϵ

    D = length(points[1])
    n_pts = length(points)

    axisminima = minimum.([minimum.([pt[i] for pt in points]) for i = 1:D])
    axismaxima = maximum.([maximum.([pt[i] for pt in points]) for i = 1:D])
    
    edgelengths = Vector{Float64}(undef, D)

    # Dictated by data ranges
    if ϵ isa Float64
        edgelengths = [ϵ for i in 1:D]
    elseif ϵ isa Vector{Float64}
        edgelengths .= ϵ
    elseif ϵ isa Int
        edgeslengths_nonadjusted = (axismaxima  - axisminima) / ϵ
        edgelengths = ((axismaxima + (edgeslengths_nonadjusted ./ 100)) - axisminima) ./ ϵ
    elseif ϵ isa Vector{Int}
        edgeslengths_nonadjusted = (axismaxima  .- axisminima) ./ ϵ
        edgelengths = ((axismaxima .+ (edgeslengths_nonadjusted ./ 100)) .- axisminima) ./ ϵ
    
    # Custom data ranges
    elseif ϵ isa Tuple{Vector{Tuple{Float64, Float64}}, Int}
        # We have predefined axis minima and axis maxima.
        n_bins = ϵ[2]
        stepsizes = zeros(Float64, D)
        edgelengths = zeros(Float64, D)

        for i = 1:D
            edgelengths[i] = (maximum(ϵ[1][i]) - minimum(ϵ[1][i]))/n_bins
            axisminima[i] = minimum(ϵ[1][i])
        end
    end

    axisminima, edgelengths
end

"""
    get_edgelengths(pts, binning_scheme::RectangularBinning) -> Vector{Float}

Return the box edge length along each axis resulting from discretizing `pts` on a 
rectangular grid specified by `binning_scheme`.

# Example 

```julia
using DynamicalSystems, CausalityToolsBase
pts = Dataset([rand(5) for i = 1:1000])

get_edgelengths(pts, RectangularBinning(0.6))
get_edgelengths(pts, RectangularBinning([0.5, 0.3, 0.3, 0.4, 0.4]))
get_edgelengths(pts, RectangularBinning(8))
get_edgelengths(pts, RectangularBinning([10, 8, 5, 4, 22]))
```
"""
function get_edgelengths end

get_edgelengths(points, ϵ::RectangularBinning) = get_minima_and_edgelengths(points, ϵ)[2]

