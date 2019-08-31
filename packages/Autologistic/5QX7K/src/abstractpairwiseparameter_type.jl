"""
    AbstractPairwiseParameter

Abstract type representing the pairwise part of an autologistic regression model.

All concrete subtypes should have the following fields:

*   `G::SimpleGraph{Int}` -- The graph for the model.
*   `count::Int`  -- The number of observations.

In addition to `getindex()` and `setindex!()`, any concrete subtype 
`P<:AbstractPairwiseParameter` should also have the following methods defined:

*   `getparameters(P)`, returning a Vector{Float64}
*   `setparameters!(P, newpar::Vector{Float64})` for setting parameter values.

Note that indexing is performance-critical and should be implemented carefully in 
subtypes.  

The intention is that each subtype should implement a different way of parameterizing
the association matrix. The way parameters are stored and values computed is up to the
subtypes. 

This type inherits from `AbstractArray{Float64, 3}`.  The third index is to allow for 
multiple observations. `P[:,:,r]` should return the association matrix of the rth
observation in an appropriate subtype of AbstractMatrix.  It is not intended that the third 
index will be used for range or vector indexing like `P[:,:,1:5]` (though this may work 
due to AbstractArray fallbacks). 

# Examples
```jldoctest
julia> M = ALsimple(Graph(4,4));
julia> typeof(M.pairwise)
SimplePairwise
julia> isa(M.pairwise, AbstractPairwiseParameter)
true
```
"""
abstract type AbstractPairwiseParameter <: AbstractArray{Float64, 3} end

IndexStyle(::Type{<:AbstractPairwiseParameter}) = IndexCartesian()

#---- fallback methods --------------
size(p::AbstractPairwiseParameter) = (nv(p.G), nv(p.G), p.count)

function getindex(p::AbstractPairwiseParameter, I::AbstractVector, J::AbstractVector)
    error("getindex not implemented for $(typeof(p))")
end

function show(io::IO, p::AbstractPairwiseParameter)
    r, c, m = size(p)
    str = "$(size2string(p)) $(typeof(p))"
    print(io, str)
end

function show(io::IO, ::MIME"text/plain", p::AbstractPairwiseParameter)
    r, c, m = size(p)
    if m==1
        str = " with $(r) vertices.\n"
    else
        str = "\nwith $(r) vertices and $(m) observations.\n"  
    end
    print(io, "Autologistic pairwise parameter Λ of type $(typeof(p)), ",
              "$(size2string(p)) array\n", 
              "Fields:\n",
              showfields(p,2),
              "Use indexing (e.g. mypairwise[:,:,:]) to see Λ values.")
end

function showfields(p::AbstractPairwiseParameter, leadspaces=0)
    return repeat(" ", leadspaces) * 
           "(**Autologistic.showfields not implemented for $(typeof(p))**)\n"
end
