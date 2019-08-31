"""
    ALsimple

An autologistic model with a `FullUnary` unary parameter type and a `SimplePairwise`
pairwise parameter type.   This model has the maximum number of unary parameters 
(one parameter per variable per observation), and a single association parameter.

# Constructors
    ALsimple(unary::FullUnary, pairwise::SimplePairwise; 
        Y::Union{Nothing,<:VecOrMat} = nothing, 
        centering::CenteringKinds = none, 
        coding::Tuple{Real,Real} = (-1,1),
        labels::Tuple{String,String} = ("low","high"), 
        coordinates::SpatialCoordinates = [(0.0,0.0) for i=1:size(unary,1)]
    )
    ALsimple(graph::SimpleGraph{Int}, alpha::Float1D2D; 
        Y::VecOrMat = Array{Bool,2}(undef,nv(graph),size(alpha,2)), 
        λ::Float64 = 0.0, 
        centering::CenteringKinds = none, 
        coding::Tuple{Real,Real} = (-1,1),
        labels::Tuple{String,String} = ("low","high"),
        coordinates::SpatialCoordinates = [(0.0,0.0) for i=1:nv(graph)]
    )
    ALsimple(graph::SimpleGraph{Int}, count::Int = 1; 
        Y::VecOrMat = Array{Bool,2}(undef,nv(graph),size(alpha,2)), 
        λ::Float64=0.0, 
        centering::CenteringKinds=none, 
        coding::Tuple{Real,Real}=(-1,1),
        labels::Tuple{String,String}=("low","high"),
        coordinates::SpatialCoordinates=[(0.0,0.0) for i=1:nv(graph)]
    )

# Arguments
- `Y`: the array of dichotomous responses.  Any array with 2 unique values will work.
  If the array has only one unique value, it must equal one of th coding values. The 
  supplied object will be internally represented as a Boolean array.
- `λ`: the association parameter.
- `centering`: controls what form of centering to use.
- `coding`: determines the numeric coding of the dichotomous responses. 
- `labels`: a 2-tuple of text labels describing the meaning of `Y`. The first element
  is the label corresponding to the lower coding value.
- `coordinates`: an array of 2- or 3-tuples giving spatial coordinates of each vertex in
  the graph. 

# Examples
```jldoctest
julia> alpha = zeros(10, 4);       #-unary parameter values
julia> Y = rand([0, 1], 10, 4);    #-responses
julia> g = Graph(10, 20);          #-graph
julia> u = FullUnary(alpha);
julia> p = SimplePairwise(g, 4);
julia> model1 = ALsimple(u, p, Y=Y);
julia> model2 = ALsimple(g, alpha, Y=Y);
julia> model3 = ALsimple(g, 4, Y=Y);
julia> all([getfield(model1, fn)==getfield(model2, fn)==getfield(model3, fn)
            for fn in fieldnames(ALsimple)])
true
```
"""
mutable struct ALsimple{C<:CenteringKinds, 
                        R<:Real, 
                        S<:SpatialCoordinates} <: AbstractAutologisticModel
    responses::Array{Bool,2}                   
    unary::FullUnary
    pairwise::SimplePairwise
    centering::C
    coding::Tuple{R,R}           
    labels::Tuple{String,String}
    coordinates::S

    function ALsimple(y, u, p, c::C, cod::Tuple{R,R}, lab, coords::S) where {C,R,S}
        if !(size(y) == size(u) == size(p)[[1,3]])
            error("ALsimple: inconsistent sizes of Y, unary, and pairwise")
        end
        if cod[1] >= cod[2]
            error("ALsimple: must have coding[1] < coding[2]")
        end
        if lab[1] == lab[2] 
            error("ALsimple: labels must be different")
        end
        new{C,R,S}(y,u,p,c,cod,lab,coords)
    end
end


# === Constructors =============================================================
# Construct from pre-constructed unary and pairwise types.
function ALsimple(unary::FullUnary, pairwise::SimplePairwise; 
                  Y::Union{Nothing,<:VecOrMat}=nothing, 
                  centering::CenteringKinds=none, 
                  coding::Tuple{Real,Real}=(-1,1),
                  labels::Tuple{String,String}=("low","high"), 
                  coordinates::SpatialCoordinates=[(0.0,0.0) for i=1:size(unary,1)])
    (n, m) = size(unary)
    if Y==nothing
        Y = Array{Bool,2}(undef, n, m)
    else 
        Y = makebool(Y,coding) 
    end
    return ALsimple(Y,unary,pairwise,centering,coding,labels,coordinates)
end

# Construct from a graph and an array of unary parameters.
function ALsimple(graph::SimpleGraph{Int}, alpha::Float1D2D; 
                  Y::VecOrMat=Array{Bool,2}(undef,nv(graph),size(alpha,2)), 
                  λ::Float64=0.0, 
                  centering::CenteringKinds=none, 
                  coding::Tuple{Real,Real}=(-1,1),
                  labels::Tuple{String,String}=("low","high"),
                  coordinates::SpatialCoordinates=[(0.0,0.0) for i=1:nv(graph)])
    u = FullUnary(alpha)
    p = SimplePairwise(λ, graph, size(alpha,2))
    return ALsimple(makebool(Y,coding),u,p,centering,coding,labels,coordinates)
end

# Construct from a graph and a number of observations
function ALsimple(graph::SimpleGraph{Int}, count::Int=1; 
                  Y::VecOrMat=Array{Bool,2}(undef,nv(graph),count), 
                  λ::Float64=0.0, 
                  centering::CenteringKinds=none, 
                  coding::Tuple{Real,Real}=(-1,1),
                  labels::Tuple{String,String}=("low","high"),
                  coordinates::SpatialCoordinates=[(0.0,0.0) for i=1:nv(graph)])
    u = FullUnary(nv(graph),count)
    p = SimplePairwise(λ, graph, count)
    return ALsimple(makebool(Y,coding),u,p,centering,coding,labels,coordinates)
end
# ==============================================================================

# === show methods =============================================================
function show(io::IO, ::MIME"text/plain", m::ALsimple)
    print(io, "Autologistic model of type ALsimple with parameter vector [α; λ].\n",
              "Fields:\n",
              showfields(m,2))
end

function showfields(m::ALsimple, leadspaces=0)
    spc = repeat(" ", leadspaces)
    return spc * "responses    $(size2string(m.responses)) Bool array\n" *
           spc * "unary        $(size2string(m.unary)) FullUnary with fields:\n" *
           showfields(m.unary, leadspaces+15) *
           spc * "pairwise     $(size2string(m.pairwise)) SimplePairwise with fields:\n" *
           showfields(m.pairwise, leadspaces+15) *
           spc * "centering    $(m.centering)\n" *
           spc * "coding       $(m.coding)\n" * 
           spc * "labels       $(m.labels)\n" *
           spc * "coordinates  $(size2string(m.coordinates)) vector of $(eltype(m.coordinates))\n"
end
# ==============================================================================

