
export 
Lags,
Positions,
customembed,
CustomReconstruction


abstract type ReconstructionParameters end

"""
    Lags

Wrapper type for lags used when performing custom state space reconstructions.
Used in combination with `Positions` to specify how a `CustomReconstruction`
should be constructed.

## Examples

- `Lags(2, 0, -3, 1)` indicates a 4-dimensional state space reconstruction where 
    the first variable has a positive lag of 2, 
    the second variable is not lagged, 
    the third variable has a lag of -3, 
    and the fourth variable has a positive lag of 1. 
- `Lags(0, 0)` indicates a 2-dimensional state space reconstruction where both 
    variables are not lagged.
"""
struct Lags <: ReconstructionParameters
    lags
    function Lags(args...)
        lags = vcat(args...)
        
        new(lags)
    end
end

Base.getindex(l::Lags, i) = getindex(l.lags, i)
Base.length(l::Lags) = length(l.lags)
Base.iterate(l::Lags) = iterate(l.lags)
Base.iterate(l::Lags, state) = iterate(l.lags, state)

"""
    Positions

Wrapper type for the positions the different dynamical variables appear in when 
constructing a custom state space reconstruction. Used in combination with
`Lags` to specify how a `CustomReconstruction` should be constructed. Each 
of the positions must refer to a dynamical variable (column) actually present in the 
dataset.

## Examples

- `Positions(1, 2, 1, 5)` indicates a 4-dimensional state space reconstruction where 
    1. the 1st coordinate axis of the reconstruction should be formed from the 
    first variable/column of the input data.
    2. the 2nd coordinate axis of the reconstruction should be formed from the 
    2nd variable/column of the input data.
    3. the 3rd coordinate axis of the reconstruction should be formed from the 
    1st variable/column of the input data.
    4. the 4th coordinate axis of the reconstruction should be formed from the 
    5th variable/column of the input data.

- `Positions(-1, 2)` indicates a 2-dimensional reconstruction, but will not work, because 
    each position must refer to the index of a dynamical variable (column) of a dataset 
    (indexed from 1 and up).
"""
struct Positions <: ReconstructionParameters
    positions
    
    function Positions(args...)
        pos = vcat(args...)
        if !all(pos .> 0)
            throw(ArgumentError("Positions must refer to the index of dynamical variables present in the dataset (cannot be zero or negative)"))
        end
        
        new(pos)
    end
end
Base.getindex(l::Positions, i) = getindex(l.positions, i)
Base.length(l::Positions) = length(l.positions)
Base.iterate(l::Positions) = iterate(l.positions)
Base.iterate(l::Positions, state) = iterate(l.positions, state)

"""
    CustomReconstruction

A type that holds a custom delay reconstruction constructed by `customembed`.

# Fields 
- **`reconstructed_pts::Dataset`**: The reconstructed points.
"""
struct CustomReconstruction{dim, T}
    reconstructed_pts::Dataset{dim, T}
    
    CustomReconstruction(d::Dataset{dim, T}) where {dim, T} = new{dim, T}(d) 
    
    function CustomReconstruction(pts::Vector{VT}) where VT
        CustomReconstruction(Dataset(pts))
    end
            
    function CustomReconstruction(pts::AbstractArray{T, 2}) where T
        if size(pts, 1) > size(pts, 2)
            CustomReconstruction(Dataset(pts))
        else
            CustomReconstruction(Dataset(transpose(pts)))
        end
    end
end


function verify_valid_positions!(positions::Positions, dim::Int)
    if any(positions .> dim)
        outside_pos = positions[findall(positions .> dim)]
        ndims = length(positions)
        throw(ArgumentError("Position(s) $outside_pos refer to variables not present in the dataset, which has only $ndims variables"))
    end
end

function CustomReconstruction(pts::Vector{VT}, positions::Positions, lags::Lags) where {VT}
    dim = length(pts[1])
    T = eltype(pts[1])

    verify_valid_positions!(positions, dim)
    
    customembed(pts, positions, lags)        
end
    
function CustomReconstruction(pts::AbstractArray{T, 2}, positions::Positions, lags::Lags) where {T}
    dim = minimum(size(pts))

    verify_valid_positions!(positions, dim)

    if size(pts, 1) > size(pts, 2)
        return customembed(Dataset(pts), positions, lags)
    else
        return customembed(Dataset(transpose(pts)), positions, lags)
    end 
end
        
function CustomReconstruction(pts::Dataset{dim, T}, positions::Positions, lags::Lags) where {dim, T}
    verify_valid_positions!(positions, dim)
    customembed(pts, positions, lags)
end

function Base.show(io::IO, cr::CustomReconstruction{dim, T} where {dim, T}) 
    println(string(typeof(cr)))
    show(cr.reconstructed_pts)
end

Base.length(r::CustomReconstruction) = length(r.reconstructed_pts)
Base.size(r::CustomReconstruction) = size(r.reconstructed_pts)
Base.getindex(r::CustomReconstruction, i) = getindex(r.reconstructed_pts, i)
Base.getindex(r::CustomReconstruction, i, j) = getindex(r.reconstructed_pts, i, j)
Base.firstindex(r::CustomReconstruction) = firstindex(r.reconstructed_pts)
Base.lastindex(r::CustomReconstruction) = lastindex(r.reconstructed_pts)
Base.iterate(r::CustomReconstruction) = iterate(r.reconstructed_pts)
Base.iterate(r::CustomReconstruction, state) = iterate(r.reconstructed_pts, state)
Base.eltype(r::CustomReconstruction) = eltype(r.reconstructed_pts)
Base.IndexStyle(r::CustomReconstruction) = IndexStyle(r.reconstructed_pts)



function fill_embedding_pts!(embeddingpts, pts, start_idxs, positions)
    npts = length(embeddingpts)
    edim = length(positions)
    
    @inbounds for j = 1:edim
        for i = 1:npts
            embeddingpts[i][j] = pts[start_idxs[j] + i][positions[j]]
        end
    end
end

"""
    customembed(pts, positions::Positions, lags::Lags)

Do custom state space reconstructions with `customembed(pts, positions::Positions, lags::Lags)`. 
This function acts almost as `DynamicalSystems.reconstruct`, but allows for more flexibility in 
the ordering of dynamical variables and allows for negative lags. The `positions` variable 
indicates which dynamical variables are mapped to which variables in the final 
reconstruction, while `lags` indicates the lags for each of the embedding variables. 

Example: `customembed([rand(3) for i = 1:50], Positions(1, 2, 1, 3), Lags(0, 0, 1, -2)` 
gives a 4-dimensional embedding with state vectors `(x1(t), x2(t), x1(t + 1), x3(t - 2))`. 

Note: `customembed` expects an array of *state vectors*, i.e. `pts[k]` must refer to the 
`k`th point of the dataset, not the `k`th dynamical variable/column.*. To embed a vector of 
time series, load `DynamicalSystems` and wrap the time series in a `Dataset` first, e.g. if 
`x = rand(100); y = rand(100)` are two time series, then 
`customembed(Dataset(x, y), Positions(1, 2, 2), Lags(0, 0, 1)` will create the embedding with 
state vectors `(x(t), y(t), y(t + 1))`.

Pre-embedded points may be wrapped in a `CustomReconstruction` instance by simply calling 
`customembed(preembedded_pts)` without any position/lag instructions.
"""
function customembed end 

"""
    customembed(pts, positions::Positions, lags::Lags)
    
Creates a custom embedding from a set of points (`pts`), 
where the i-th embedding column/variable is constructed by
lagging the `positions[i]`-th variable/column of `pts` by 
a lag of `lags[i]`. 

*Note: `pts[k]` must refer to the `k`th point of the dataset,
not the `k`th dynamical variable/column.*

# Example 

Say we want to construct an appropriate delay reconstruction for transfer entropy (TE) 
analysis

```math
E = \\{S_{pp}, T_{pp}, T_f \\}= \\{x_t, (y_t, y_{t-\\tau}), y_{t+\\eta} \\}``),
```

so that we're computing the following TE

```math
TE_{x \\to y} =  \\int_E P(x_t, y_{t-\\tau} y_t, y_{t + \\eta}) \\log{\\left( \\dfrac{P(y_{t + \\eta} | (y_t, y_{t - \\tau}, x_t)}{P(y_{t + \\eta} | y_t, y_{t-\\tau})} \\right)}.
```

We'll use a prediction lag ``\\eta = 2`` and use first minima of the lagged mutual 
information function for the embedding delay ``\\tau``.

```julia
using CausalityToolsBase, DynamicalSystems

x = rand(100)
y = rand(100)
D = Dataset(x, y)
embedlag = optimal_delay(y)
CustomReconstruction(D, Positions(2, 2, 2, 1), Lags(2, 0, embedlag, 0))
```
"""
function customembed(pts, positions::Positions, lags::Lags)
        
    # Dimension of the original space 
    dim = length(pts[1])
    verify_valid_positions!(positions, dim)

    positions, lags = positions.positions, lags.lags
    
    # Dimension of the embedding space
    @assert length(positions) == length(lags)
    edim = length(lags)

    minlag, maxlag = minimum(lags), maximum(lags)
    npts = length(pts) - (maxlag + abs(minlag))
    Tpts = eltype(pts[1])
    embeddingpts = [zeros(Tpts, edim) for i = 1:npts]
    start_idxs = zeros(Int, edim)
    
    # Determine starting indices for each axis.
    for i = 1:edim
        lag = lags[i]
        pos = positions[i]
        if lag > 0
            start_idxs[i] = (abs(minlag)) + lag
        elseif lag < 0
            start_idxs[i] = (abs(minlag)) - abs(lag)
        elseif lag == 0
            start_idxs[i] = abs(minlag)
        end
    end
            
    fill_embedding_pts!(embeddingpts, pts, start_idxs, positions)     
    
    return CustomReconstruction(Dataset(embeddingpts))
end


function customembed(pts)
    CustomReconstruction(pts)
end


function encode(points::CustomReconstruction{dim, T}, reference_point, edgelengths) where {dim, T}
    [encode(points[i], reference_point, edgelengths) for i = 1:length(points)]
end

export encode