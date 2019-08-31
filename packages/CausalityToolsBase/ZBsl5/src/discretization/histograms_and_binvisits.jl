export 
joint_visits,
marginal_visits,
non0hist

"""
    joint_visits(points, binning_scheme::RectangularBinning)

Determine which bins are visited by `points` given the rectangular binning
scheme `ϵ`. Bins are referenced relative to the axis minimum.

# Example 

```julia
using DynamicalSystems, CausalityToolsBase
pts = Dataset([rand(5) for i = 1:100]);

joint_visits(pts, RectangularBinning(0.2))
```
"""
function joint_visits(points, binning_scheme::RectangularBinning)
    axis_minima, box_edge_lengths = get_minima_and_edgelengths(points, binning_scheme)
    encode(points, axis_minima, box_edge_lengths)
end

"""
    marginal_visits(points, binning_scheme::RectangularBinning, dims)

Determine which bins are visited by `points` given the rectangular binning
scheme `ϵ`, only along the desired dimensions `dims`. Bins are referenced 
relative to the axis minimum.

# Example 

```julia
using DynamicalSystems, CausalityToolsBase
pts = Dataset([rand(5) for i = 1:100]);

# Marginal visits along dimension 3 and 5
marginal_visits(pts, RectangularBinning(0.3), [3, 5])

# Marginal visits along dimension 2 through 5
marginal_visits(pts, RectangularBinning(0.3), 2:5)
```
"""
function marginal_visits(points, binning_scheme::RectangularBinning, dims)
    axis_minima, box_edge_lengths = get_minima_and_edgelengths(points, binning_scheme)
    dim = length(axis_minima)
    if sort(collect(dims)) == sort(collect(1:dim))
        joint_visits(points, binning_scheme)
    else
        [encode(pt, axis_minima, box_edge_lengths)[dims] for pt in points]
    end
end

"""
    marginal_visits(joint_visits, dims)

Given a set of precomputed joint visited bins over some binning, return the marginal along 
dimensions `dims`.

# Example 

```julia
using DynamicalSystems, CausalityToolsBase
pts = Dataset([rand(5) for i = 1:100]);

# First compute joint visits, then marginal visits along dimensions 1 and 4
jv = joint_visits(pts, RectangularBinning(0.2))
marginal_visits(jv, [1, 4])
```
"""
function marginal_visits(joint_visits, dims)
    [bin[dims] for bin in joint_visits]
end

"""
    non0hist(bin_visits)

Return the unordered histogram (vistitation frequency) over the array of `bin_visits`,
which is a vector containing bin encodings (each point encoded by an integer vector).

This method extends `ChaosTools.non0hist`.

# Example 
```julia 
using DynamicalSystems, CausalityToolsBase
pts = Dataset([rand(5) for i = 1:100]);

# Histograms from precomputed joint/marginal visitations 
jv = joint_visits(pts, RectangularBinning(10))
mv = marginal_visits(pts, RectangularBinning(10), 1:3)

h1 = non0hist(jv)
h2 = non0hist(mv)

# Test that we're actually getting a normalised histograms
sum(h1) ≈ 1.0, sum(h2) ≈ 1.0
```
"""
function non0hist(bin_visits::Vector{T}) where {T <: Union{Vector, SVector, MVector}}
    L = length(bin_visits)
    hist = Vector{Float64}()

    # Reserve enough space for histogram:
    sizehint!(hist, L)

    sort!(bin_visits, alg = QuickSort)

    # Fill the histogram by counting consecutive equal bins:
    prev_bin = bin_visits[1]
    count = 1
    @inbounds for i in 2:L
        bin = bin_visits[i]
        if bin == prev_bin
            count += 1
        else
            push!(hist, count/L)
            prev_bin = bin
            count = 1
        end
    end
    push!(hist, count/L)

    # Shrink histogram capacity to fit its size:
    sizehint!(hist, length(hist))

    return hist
end

"""
    non0hist(points, binning_scheme::RectangularBinning, dims)

Determine which bins are visited by `points` given the rectangular `binning_scheme`, 
considering only the marginal along dimensions `dims`. Bins are referenced 
relative to the axis minima.

Returns the unordered histogram (visitation frequency) over the array of bin visits.

This method extends `ChaosTools.non0hist`.


# Example 
```julia 
using DynamicalSystems
pts = Dataset([rand(5) for i = 1:100]);

# Histograms directly from points given a rectangular binning scheme
h1 = non0hist(pts, RectangularBinning(0.2), 1:3) 
h2 = non0hist(pts, RectangularBinning(0.2), [1, 2])

# Test that we're actually getting normalised histograms 
sum(h1) ≈ 1.0, sum(h2) ≈ 1.0
```
"""
function non0hist(points, binning_scheme::RectangularBinning, dims)
    bin_visits = marginal_visits(points, binning_scheme, dims)
    L = length(bin_visits)
    hist = Vector{Float64}()

    # Reserve enough space for histogram:
    sizehint!(hist, L)

    sort!(bin_visits, alg = QuickSort)

    # Fill the histogram by counting consecutive equal bins:
    prev_bin = bin_visits[1]
    count = 1
    @inbounds for i in 2:L
        bin = bin_visits[i]
        if bin == prev_bin
            count += 1
        else
            push!(hist, count/L)
            prev_bin = bin
            count = 1
        end
    end
    push!(hist, count/L)

    # Shrink histogram capacity to fit its size:
    sizehint!(hist, length(hist))

    return hist
end