"""
    ALRsimple

An autologistic regression model with "simple smoothing":  the unary parameter is of type
`LinPredUnary`, and the pairwise parameter is of type `SimplePairwise`.

# Constructors
    ALRsimple(unary::LinPredUnary, pairwise::SimplePairwise;
        Y::Union{Nothing,<:VecOrMat} = nothing,
        centering::CenteringKinds = none, 
        coding::Tuple{Real,Real} = (-1,1),
        labels::Tuple{String,String} = ("low","high"), 
        coordinates::SpatialCoordinates = [(0.0,0.0) for i=1:size(unary,1)]
    )
    ALRsimple(graph::SimpleGraph{Int}, X::Float2D3D; 
        Y::VecOrMat = Array{Bool,2}(undef,nv(graph),size(X,3)),
        β::Vector{Float64} = zeros(size(X,2)),
        λ::Float64 = 0.0, 
        centering::CenteringKinds = none, 
        coding::Tuple{Real,Real} = (-1,1),
        labels::Tuple{String,String} = ("low","high"),
        coordinates::SpatialCoordinates = [(0.0,0.0) for i=1:nv(graph)]
    )

# Arguments
- `Y`: the array of dichotomous responses.  Any array with 2 unique values will work.
  If the array has only one unique value, it must equal one of the coding values. The 
  supplied object will be internally represented as a Boolean array.
- `β`: the regression coefficients.
- `λ`: the association parameter.
- `centering`: controls what form of centering to use.
- `coding`: determines the numeric coding of the dichotomous responses. 
- `labels`: a 2-tuple of text labels describing the meaning of `Y`. The first element
  is the label corresponding to the lower coding value.
- `coordinates`: an array of 2- or 3-tuples giving spatial coordinates of each vertex in
  the graph. 

# Examples
```jldoctest
julia> using LightGraphs
julia> X = rand(10,3);            #-predictors
julia> Y = rand([-2, 3], 10);     #-responses
julia> g = Graph(10,20);          #-graph
julia> u = LinPredUnary(X);
julia> p = SimplePairwise(g);
julia> model1 = ALRsimple(u, p, Y=Y);
julia> model2 = ALRsimple(g, X, Y=Y);
julia> all([getfield(model1, fn)==getfield(model2, fn) for fn in fieldnames(ALRsimple)])
true
```
"""
mutable struct ALRsimple{C<:CenteringKinds,
                         R<:Real,
                         S<:SpatialCoordinates} <: AbstractAutologisticModel
    responses::Array{Bool,2}                   
    unary::LinPredUnary
    pairwise::SimplePairwise
    centering::C
    coding::Tuple{R,R}           
    labels::Tuple{String,String}
    coordinates::S

    function ALRsimple(y, u, p, c::C, cod::Tuple{R,R}, lab, coords::S) where {C,R,S}
        if !(size(y) == size(u) == size(p)[[1,3]])
            error("ALRsimple: inconsistent sizes of Y, unary, and pairwise")
        end
        if cod[1] >= cod[2]
            error("ALRsimple: must have coding[1] < coding[2]")
        end
        if lab[1] == lab[2] 
            error("ALRsimple: labels must be different")
        end
        new{C,R,S}(y,u,p,c,cod,lab,coords)
    end
end


# === Constructors =============================================================
# Construct from pre-constructed unary and pairwise types.
function ALRsimple(unary::LinPredUnary, pairwise::SimplePairwise; 
                   Y::Union{Nothing,<:VecOrMat}=nothing, 
                   centering::CenteringKinds=none, 
                   coding::Tuple{Real,Real}=(-1,1),
                   labels::Tuple{String,String}=("low","high"), 
                   coordinates::SpatialCoordinates=[(0.0,0.0) for i=1:size(unary,1)])
    (n, m) = size(unary)
    if Y==nothing
        Y = Array{Bool,2}(undef, n, m)
    else
        Y = makebool(Y, coding)
    end
    return ALRsimple(Y,unary,pairwise,centering,coding,labels,coordinates)
end

# Construct from a graph and an X matrix.
function ALRsimple(graph::SimpleGraph{Int}, X::Float2D3D; 
                   Y::VecOrMat=Array{Bool,2}(undef,nv(graph),size(X,3)), 
                   β::Vector{Float64}=zeros(size(X,2)), 
                   λ::Float64=0.0, centering::CenteringKinds=none, 
                   coding::Tuple{Real,Real}=(-1,1),
                   labels::Tuple{String,String}=("low","high"),
                   coordinates::SpatialCoordinates=[(0.0,0.0) for i=1:nv(graph)])
    u = LinPredUnary(X, β)
    p = SimplePairwise(λ, graph, size(X,3))
    return ALRsimple(makebool(Y,coding),u,p,centering,coding,labels,coordinates)
end
# ==============================================================================

# === show methods =============================================================
function show(io::IO, ::MIME"text/plain", m::ALRsimple)
    print(io, "Autologistic regression model of type ALRsimple with parameter vector [β; λ].\n",
              "Fields:\n",
              showfields(m,2))
end

function showfields(m::ALRsimple, leadspaces=0)
    spc = repeat(" ", leadspaces)
    return spc * "responses    $(size2string(m.responses)) Bool array\n" *
           spc * "unary        $(size2string(m.unary)) LinPredUnary with fields:\n" *
           showfields(m.unary, leadspaces+15) *
           spc * "pairwise     $(size2string(m.pairwise)) SimplePairwise with fields:\n" *
           showfields(m.pairwise, leadspaces+15) *
           spc * "centering    $(m.centering)\n" *
           spc * "coding       $(m.coding)\n" * 
           spc * "labels       $(m.labels)\n" *
           spc * "coordinates  $(size2string(m.coordinates)) vector of $(eltype(m.coordinates))\n"
end
# ==============================================================================



