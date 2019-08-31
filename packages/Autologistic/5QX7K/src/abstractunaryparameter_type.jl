"""
    AbstractUnaryParameter

Abstract type representing the unary part of an autologistic regression model.

This type inherits from AbstractArray{Float64, 2}. The first dimension is for
vertices/variables in the graph, and the second dimension is for observations.  It is
two-dimensional even if there is only one observation. 

Implementation details are left to concrete subtypes, and will depend on how the unary
terms are parametrized.  Note that indexing is performance-critical.

Concrete subtypes should implement `getparameters`, `setparameters!`, and `showfields`.

# Examples
```jldoctest
julia> M = ALsimple(Graph(4,4));
julia> typeof(M.unary)
FullUnary
julia> isa(M.unary, AbstractUnaryParameter)
true
```
"""
abstract type AbstractUnaryParameter <: AbstractArray{Float64, 2} end
IndexStyle(::Type{<:AbstractUnaryParameter}) = IndexCartesian()

function show(io::IO, u::AbstractUnaryParameter)
    r, c = size(u)
    str = "$(r)×$(c) $(typeof(u))"
    print(io, str)
end

function show(io::IO, ::MIME"text/plain", u::AbstractUnaryParameter)
    r, c = size(u)
    if c==1
        str = "\n$(size2string(u)) array with average value $(round(mean(u), digits=3)).\n"
    else
        str = " $(size2string(u)) array.\n"  
    end
    print(io, "Autologistic unary parameter α of type $(typeof(u)),",
              str, 
              "Fields:\n",
              showfields(u,2),
              "Use indexing (e.g. myunary[:,:]) to see α values.")
end

function showfields(u::AbstractUnaryParameter, leadspaces=0)
    return repeat(" ", leadspaces) * 
           "(**Autologistic.showfields not implemented for $(typeof(u))**)\n"
end
