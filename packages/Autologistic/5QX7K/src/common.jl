# Type Aliases
""" Type alias for `Union{Array{T,1}, Array{T,2}} where T` """
const VecOrMat = Union{Array{T,1}, Array{T,2}} where T

""" Type alias for `Union{Array{Float64,1},Array{Float64,2}}` """
const Float1D2D = Union{Array{Float64,1},Array{Float64,2}}

""" Type alias for `Union{Array{Float64,2},Array{Float64,3}}` """
const Float2D3D = Union{Array{Float64,2},Array{Float64,3}}

""" Type alias for `Union{Array{NTuple{2,T},1},Array{NTuple{3,T},1}} where T<:Real` """
const SpatialCoordinates = Union{Array{NTuple{2,T},1},Array{NTuple{3,T},1}} where T<:Real

# somewhat arbitrary constants in sampling algorithms
const maxepoch = 40     #used in cftp_reuse_seeds
const ntestchains = 15  #used in blocksize_estimate

# Enumerations
"""
    CenteringKinds

An enumeration to facilitate choosing a form of centering for the model.  Available
choices are: 

- `none`: no centering (centering adjustment equals zero).
- `expectation`: the centering adjustment is the expected value of the response under the
  assumption of independence (this is what has been used in the "centered autologistic 
  model").
- `onehalf`: a constant value of centering adjustment equal to 0.5 (this produces the
  "symmetric autologistic model" when used with 0,1 coding).

The default/recommended model has centering of `none` with (-1, 1) coding.

# Examples
```jldoctest
julia> CenteringKinds
Enum CenteringKinds:
none = 0
expectation = 1
onehalf = 2
```
"""
@enum CenteringKinds none expectation onehalf

"""
    SamplingMethods

An enumeration to facilitate choosing a method for random sampling from autologistic models.
Available choices are:

- `Gibbs`:  Gibbs sampling.
- `perfect_bounding_chain`: Perfect sampling, using a bounding chain algorithm.
- `perfect_reuse_samples`: Perfect sampling. CFTP implemented by reusing random numbers.
- `perfect_reuse_seeds`: Perfect sampling. CFTP implemented by reusing RNG seeds.
- `perfect_read_once`: Perfect sampling. Read-once CFTP implementation.

All of the perfect sampling methods are implementations of coupling from the past (CFTP).
`perfect_bounding_chain` uses a bounding chain approach that holds even when Λ contains
negative elements; the other three options rely on a monotonicity argument that requires
Λ to have only positive elements (though they should work similar to Gibbs sampling in
that case).

Different perfect sampling implementations might work best for different models, and
parameter settings exist where perfect sampling coalescence might take a prohibitively long
time.  For these reasons, Gibbs sampling is the default in `sample`.

# Examples
```jldoctest
julia> SamplingMethods
Enum SamplingMethods:
Gibbs = 0
perfect_reuse_samples = 1
perfect_reuse_seeds = 2
perfect_read_once = 3
perfect_bounding_chain = 4
```
"""
@enum SamplingMethods Gibbs perfect_reuse_samples perfect_reuse_seeds perfect_read_once perfect_bounding_chain


"""
    makebool(v::VecOrMat, vals=nothing)

Makes a 2D array of Booleans out of a 1- or 2-D input.  The 2nd argument `vals` optionally
can be a 2-tuple (low, high) specifying the two possible values in `v` (useful for the case
where all elements of `v` take one value or the other).

- If `v` has more than 2 unique values, throws an error.
- If `v` has exactly 2 unique values, use those to set the coding (ignore `vals`).
- If `v` has 1 unique value, use `vals` to determine if it's the high or low value (throw
  an error if the single value isn't in `vals`).

# Examples
```jldoctest
julia> makebool([1.0 2.0; 1.0 2.0])
2×2 Array{Bool,2}:
 false  true
 false  true

julia> makebool(["yes", "no", "no"])
3×1 Array{Bool,2}:
  true
 false
 false

julia> [makebool([1, 1, 1], (-1,1)) makebool([1, 1, 1], (1, 2))]
3×2 Array{Bool,2}:
 true  false
 true  false
 true  false
```
"""
function makebool(v::VecOrMat, vals=nothing)
    if ndims(v)==1
        v = v[:,:]    #**convet to 2D, not sure the logic behind [:,:] index
    end
    if typeof(v) == Array{Bool,2} 
        return v 
    end
    (nrow, ncol) = size(v)
    out = Array{Bool}(undef, nrow, ncol)
    nv = length(unique(v))
    if nv > 2
        error("The input has more than two values.")
    elseif nv == 2
        lower = minimum(v)
    elseif typeof(vals) <: NTuple{2} && v[1] in vals
        lower = vals[1]
    else
        error("One unique value. Could not assign true or false.")
    end
    for i in 1:nrow
        for j in 1:ncol
            v[i,j]==lower ? out[i,j] = false : out[i,j] = true
        end
    end
    return out
end

"""
    makecoded(b::VecOrMat, coding::Tuple{Real,Real})

Convert Boolean responses into coded values.  The first argument is boolean.
Returns a 2D array of Float64.  

# Examples
```jldoctest
julia> makecoded([true, false, false, true], (-1, 1))
4×1 Array{Float64,2}:
  1.0
 -1.0
 -1.0
  1.0
```
"""
function makecoded(b::VecOrMat, coding::Tuple{Real,Real})
    lo = Float64(coding[1])
    hi = Float64(coding[2])
    if ndims(b)==1
        b = b[:,:]
    end
    n, m = size(b)
    out = Array{Float64,2}(undef, n, m)
    for j = 1:m
        for i = 1:n
            out[i,j] = b[i,j] ? hi : lo
        end
    end
    return out
end


"""
    makegrid4(r::Int, c::Int, xlim::Tuple{Real,Real}=(0.0,1.0), 
              ylim::Tuple{Real,Real}=(0.0,1.0))

Returns a named tuple `(:G, :locs)`, where `:G` is a graph, and `:locs` is an array of 
numeric tuples.  Vertices of `:G` are laid out in a rectangular, 4-connected grid with 
`r` rows and `c` columns.  The tuples in `:locs` contain the spatial coordinates of each
vertex.  Optional arguments `xlim` and `ylim` determine the bounds of the rectangular 
layout.

# Examples
```jldoctest
julia> out4 = makegrid4(11, 21, (-1,1), (-10,10));
julia> nv(out4.G) == 11*21                  #231
true
julia> ne(out4.G) == 11*20 + 21*10          #430
true
julia> out4.locs[11*10 + 6] == (0.0, 0.0)   #location of center vertex.
true
```
"""
function makegrid4(r::Int, c::Int, xlim::Tuple{Real,Real}=(0.0,1.0), 
               ylim::Tuple{Real,Real}=(0.0,1.0))

    # Create graph with r*c vertices, no edges
    G = Graph(r*c)

    # loop through vertices. Number vertices columnwise.
    for i in 1:r*c
        if mod(i,r) !== 1       # N neighbor
            add_edge!(G,i,i-1) 
        end
        if i <= (c-1)*r         # E neighbor
            add_edge!(G,i,i+r)
        end 
        if mod(i,r) !== 0       # S neighbor
          add_edge!(G,i,i+1)
        end
        if i > r                # W neighbor
            add_edge!(G,i,i-r)
        end
    end

    rngx = range(xlim[1], stop=xlim[2], length=c)
    rngy = range(ylim[1], stop=ylim[2], length=r)
    locs = [(rngx[i], rngy[j]) for i in 1:c for j in 1:r]

    return (G=G, locs=locs)
end


"""
    makegrid8(r::Int, c::Int, xlim::Tuple{Real,Real}=(0.0,1.0), 
              ylim::Tuple{Real,Real}=(0.0,1.0))

Returns a named tuple `(:G, :locs)`, where `:G` is a graph, and `:locs` is an array of 
numeric tuples.  Vertices of `:G` are laid out in a rectangular, 8-connected grid with 
`r` rows and `c` columns.  The tuples in `:locs` contain the spatial coordinates of each
vertex.  Optional arguments `xlim` and `ylim` determine the bounds of the rectangular 
layout.

# Examples
```jldoctest
julia> out8 = makegrid8(11, 21, (-1,1), (-10,10));
julia> nv(out8.G) == 11*21                      #231
true
julia> ne(out8.G) == 11*20 + 21*10 + 2*20*10    #830
true
julia> out8.locs[11*10 + 6] == (0.0, 0.0)       #location of center vertex.
true
```
"""
function makegrid8(r::Int, c::Int, xlim::Tuple{Real,Real}=(0.0,1.0), 
               ylim::Tuple{Real,Real}=(0.0,1.0))

    # Create the 4-connected graph
    G, locs = makegrid4(r, c, xlim, ylim)

    # loop through vertices and add the diagonal edges.
    for i in 1:r*c
        if (mod(i,r) !== 1) && (i<=(c-1)*r)    # NE neighbor
            add_edge!(G,i,i+r-1) 
        end
        if (mod(i,r) !== 0) && (i <= (c-1)*r)  # SE neighbor
            add_edge!(G,i,i+r+1)
        end 
        if (mod(i,r) !== 0) && (i > r)         # SW neighbor
          add_edge!(G,i,i-r+1)
        end
        if (mod(i,r) !== 1) && (i > r)         # NW neighbor
            add_edge!(G,i,i-r-1)
        end
    end

    return (G=G, locs=locs)
end


"""
    makespatialgraph(coords::C, δ::Real) where C<:SpatialCoordinates

Returns a named tuple `(:G, :locs)`, where `:G` is a graph, and `:locs` is an array of 
numeric tuples.  Each element of `coords` is a 2- or 3-tuple of spatial coordinates, and
this argument is returned unchanged as `:locs`.  The graph `:G` has `length(coords)`
vertices, with edges connecting every pair of vertices within Euclidean distance `δ` of
each other. 

# Examples
```jldoctest
julia> c = [(Float64(i), Float64(j)) for i = 1:5 for j = 1:5];
julia> out = makespatialgraph(c, sqrt(2));
julia> out.G
{25, 72} undirected simple Int64 graph

julia> length(out.locs)
25
```
"""
function makespatialgraph(coords::C, δ::Real) where C<:SpatialCoordinates
    #Replace coords by an equivalent tuple of Float64, for consistency
    n = length(coords)
    locs = [Float64.(coords[i]) for i = 1:n]
    #Make the graph and add edges
    G = Graph(n)
    for i in 1:n
        for j in i+1:n 
            if norm(locs[i] .- locs[j]) <= δ
                add_edge!(G,i,j)
            end
        end
    end
    return (G=G, locs=locs)
end


# Open data sets 
function datasets(name::String)
    if name=="pigmentosa"
        dfpath = joinpath(dirname(pathof(Autologistic)), "..", "assets", "pigmentosa.csv")
        return read(dfpath)
    elseif name=="hydrocotyle"
        dfpath = joinpath(dirname(pathof(Autologistic)), "..", "assets", "hydrocotyle.csv")
        return read(dfpath)
    else
        error("Name is not one of the available options.")
    end
end


# Make size into strings like 10×5×2 (for use in show methods)
function size2string(x::T) where T<:AbstractArray
    d = size(x)
    n = length(d)
    if n ==1 
        return "$(d[1])-element"
    else
        str = "$(d[1])" 
        for i = 2:n
            str *= "×"
            str *= "$(d[i])"
        end
        return str
    end
end


# Approximate the Hessian of fcn at the point x, using a step width h.
# Uses the O(h^2) central difference approximation.
# Intended for obtaining standard errors from ML fitting.
function hess(fcn, x, h=1e-6)  
    n = length(x)
    H = zeros(n,n)
    hI = h*Matrix(1.0I,n,n)  #ith column of hI has h in ith position, 0 elsewhere.
    
    # Fill up the top half of the matrix
    for i = 1:n        
        for j = i:n
            h1 = hI[:,i]
            h2 = hI[:,j];
            H[i,j] = (fcn(x+h1+h2)-fcn(x+h1-h2)-fcn(x-h1+h2)+fcn(x-h1-h2)) / (4*h^2)
        end
    end
    
    # Fill the bottom half of H (use symmetry), and return
    return H + triu(H,1)'
end

# Takes a named tuple (arising from keyword argument list) and produces two named tuples:
# one with the arguments for optimise(), and one for arguments to sample()
# Usage: optimargs, sampleargs = splitkw(keyword_tuple)
splitkw = function(kwargs)
    optimnames = fieldnames(typeof(Options()))
    samplenames = (:method, :indices, :average, :config, :burnin, :verbose)
    optimargs = Dict{Symbol,Any}()
    sampleargs = Dict{Symbol,Any}()
    for (symb, val) in pairs(kwargs)
        if symb in optimnames
            push!(optimargs, symb => val)
        end
        if symb in samplenames
            push!(sampleargs, symb => val)
        end
    end
    return (;optimargs...), (;sampleargs...)
end
