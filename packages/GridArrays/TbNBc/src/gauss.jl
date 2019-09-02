"""
    struct ChebyshevNodes{T} <: AbstractIntervalGrid{T}

A grid with chebyshev nodes on [-1,1].

# Example
```jldocs
julia> ChebyshevExtremae(4)
4-element ChebyshevExtremae{Float64}:
  1.0
  0.5000000000000001
 -0.4999999999999998
 -1.0
```
"""
struct ChebyshevTNodes{T} <: AbstractIntervalGrid{T}
    n   ::  Int
end

const ChebyshevNodes = ChebyshevTNodes
const ChebyshevPoints = ChebyshevTNodes
unsafe_getindex(g::ChebyshevTNodes{T}, i::Int) where {T} = T(-1)*cos((i-T(1)/2) * T(pi) / (g.n) )


"""
    struct ChebyshevExtremae{T} <: AbstractIntervalGrid{T}

A grid with chebyshev extrema on [-1,1].

# Example
```jldocs
julia> ChebyshevExtremae(4)
4-element ChebyshevExtremae{Float64}:
  1.0
  0.5000000000000001
 -0.4999999999999998
 -1.0
```
"""
struct ChebyshevExtremae{T} <: AbstractIntervalGrid{T}
    n   ::  Int
end

const ChebyshevPointsOfTheSecondKind = ChebyshevExtremae

# TODO: flip the values so that they are sorted
unsafe_getindex(g::ChebyshevExtremae{T}, i::Int) where {T} = i == 0 ? T(0) : cos((i-1)*T(pi) / (g.n-1) )


struct ChebyshevUNodes{T} <: AbstractIntervalGrid{T}
    n   :: Int
end

unsafe_getindex(nodes::ChebyshevUNodes{T}, i::Int) where T = cos((nodes.n + 1 - i) * convert(T,π) / (nodes.n + 1))

struct LegendreNodes{T} <: AbstractIntervalGrid{T}
    n   :: Int
    nodes   :: Vector{T}
    LegendreNodes(vector::Vector{T}) where {T} = new{T}(length(vector), vector)
end


struct LaguerreNodes{T} <: AbstractIntervalGrid{T}
    n   :: Int
    α   :: T
    nodes   :: Vector{T}
    LaguerreNodes(α::T, vector::Vector{T}) where {T} = new{T}(length(vector), α, vector)
end

struct HermiteNodes{T} <: AbstractIntervalGrid{T}
    n   :: Int
    nodes   :: Vector{T}
    HermiteNodes(vector::Vector{T}) where {T} = new{T}(length(vector), vector)
end

struct JacobiNodes{T} <: AbstractIntervalGrid{T}
    n   ::  Int
    α   ::  T
    β   ::  T
    nodes   ::Vector
    JacobiNodes(α::T, β::T, vector::Vector{T}) where {T} = new{T}(length(vector), α, β, vector)
end

for GRID in (:LegendreNodes,:HermiteNodes,:LaguerreNodes,:JacobiNodes)
    @eval unsafe_getindex(grid::$GRID, i::Int) = unsafe_getindex(grid.nodes, i)
end

for (Tp,fun) in zip((:ChebyshevTWeights,), (:chebyshevtweights_fun, ))
    @eval begin
        struct $Tp{T,N,Axes} <:FillArrays.AbstractFill{T,N,Axes}
            axes::Axes
            @inline $Tp{T, N}(sz::Axes) where Axes<:Tuple{Vararg{AbstractUnitRange,N}} where {T, N} =
                new{T,N,Axes}(sz)
            @inline $Tp{T,0,Tuple{}}(sz::Tuple{}) where T = new{T,0,Tuple{}}(sz)
        end


        @inline $Tp{T, 0}(sz::Tuple{}) where {T} = $Tp{T,0,Tuple{}}(sz)
        @inline $Tp{T, N}(sz::Tuple{Vararg{<:Integer, N}}) where {T, N} = $Tp{T,N}(Base.OneTo.(sz))
        @inline $Tp{T, N}(sz::Vararg{<:Integer, N}) where {T, N} = $Tp{T,N}(sz)
        @inline $Tp{T}(sz::Vararg{Integer,N}) where {T, N} = $Tp{T, N}(sz)
        @inline $Tp{T}(sz::SZ) where SZ<:Tuple{Vararg{Any,N}} where {T, N} = $Tp{T, N}(sz)
        @inline $Tp(sz::Vararg{Any,N}) where N = $Tp{Float64,N}(sz)
        @inline $Tp(sz::SZ) where SZ<:Tuple{Vararg{Any,N}} where N = $Tp{Float64,N}(sz)

        @inline $Tp{T,N}(A::AbstractArray{V,N}) where{T,V,N} = $Tp{T,N}(size(A))
        @inline $Tp{T}(A::AbstractArray) where{T} = $Tp{T}(size(A))
        @inline $Tp(A::AbstractArray) = $Tp(size(A))

        @inline axes(Z::$Tp) = Z.axes
        @inline size(Z::$Tp) = length.(Z.axes)
        @inline FillArrays.getindex_value(Z::$Tp) = $fun(Z)

        AbstractArray{T}(F::$Tp{T}) where T = F
        AbstractArray{T,N}(F::$Tp{T,N}) where {T,N} = F
        AbstractArray{T}(F::$Tp) where T = $Tp{T}(F.axes)
        AbstractArray{T,N}(F::$Tp{V,N}) where {T,V,N} = $Tp{T}(F.axes)
        convert(::Type{AbstractArray{T}}, F::$Tp{T}) where T = AbstractArray{T}(F)
        convert(::Type{AbstractArray{T,N}}, F::$Tp{T,N}) where {T,N} = AbstractArray{T,N}(F)
        convert(::Type{AbstractArray{T}}, F::$Tp) where T = AbstractArray{T}(F)
        convert(::Type{AbstractArray{T,N}}, F::$Tp) where {T,N} = AbstractArray{T,N}(F)

        getindex(F::$Tp{T,0}) where T = getindex_value(F)
        function getindex(F::$Tp{T}, kj::Vararg{AbstractVector{II},N}) where {T,II<:Integer,N}
            checkbounds(F, kj...)
            Fill{T}(FillArrays.getindex_value(F),length.(kj))
        end

        function getindex(A::$Tp{T}, kr::AbstractVector{Bool}) where T
            length(A) == length(kr) || throw(DimensionMismatch())
            Fill{T}(FillArrays.getindex_value(F),count(kr))
        end
        function getindex(A::$Tp{T}, kr::AbstractArray{Bool}) where T
            size(A) == size(kr) || throw(DimensionMismatch())
            Fill{T}(FillArrays.getindex_value(F),count(kr))
        end
    end
end

chebyshevtweights_fun(Z::ChebyshevTWeights{T}) where T =  convert(T,π) / convert(T,length(Z))



abstract type VectorAlias{T} <: AbstractVector{T} end
getindex(vector::VectorAlias, i::Int) = getindex(vector.vector, i)
unsafe_getindex(vector::VectorAlias, i::Int) = unsafe_getindex(vector.vector, i)
size(vector::VectorAlias) = size(vector.vector)

abstract type FunctionVector{T} <: AbstractVector{T} end
length(vector::FunctionVector) = vector.n
size(vector::FunctionVector) = (length(vector),)

function getindex(vector::FunctionVector, i::Int)
    @boundscheck (1 <= i <= length(vector)) || throw(BoundsError())
    @inbounds unsafe_getindex(vector, i)
end


struct ChebyshevUWeights{T} <: FunctionVector{T}
    n   :: Int
end

unsafe_getindex(weights::ChebyshevUWeights{T}, i::Int) where {T} =
    convert(T,π)/(weights.n + 1) * sin(convert(T,weights.n + 1 -i) / (weights.n + 1) * convert(T,π))^2

gausschebyshev(::Type{T}, n::Int) where T =
    ChebyshevTNodes{T}(n), ChebyshevTWeights{T}(n)
gausschebyshev(n::Int) = gausschebyshev(Float64, n)


gausschebyshevu(::Type{T}, n::Int) where T =
    ChebyshevUNodes{T}(n), ChebyshevUWeights{T}(n)
gausschebyshevu(n::Int) = gausschebyshevu(Float64,n)

struct LegendreWeights{T} <: VectorAlias{T}
    vector  ::  Vector{T}
end

function gausslegendre(::Type{Float64}, n::Int)
    x,w = FastGaussQuadrature.gausslegendre(n)
    LegendreNodes(x), LegendreWeights(w)
end
function gausslegendre(::Type{T}, n::Int) where T
    x,w = GaussQuadrature.legendre(T, n)
    LegendreNodes(x), LegendreWeights(w)
end
gausslegendre(n::Int) = gausslegendre(Float64, n)

struct LaguerreWeights{T} <: VectorAlias{T}
    α       ::  T
    vector  ::  Vector{T}
end

function gausslaguerre(::Type{Float64}, n::Int, α::Float64)
    x,w = FastGaussQuadrature.gausslaguerre(n, α)
    LaguerreNodes(α, x), LaguerreWeights(α, w)
end
function gausslaguerre(::Type{T}, n::Int, α::T) where T
    x,w = GaussQuadrature.laguerre(n, α)
    LaguerreNodes(α, x), LaguerreWeights(α, w)
end
gausslaguerre(n::Int, α::T) where T = gausslaguerre(T, n, α)

struct HermiteWeights{T} <: VectorAlias{T}
    vector  ::  Vector{T}
end
function gausshermite(::Type{Float64}, n::Int)
    x,w = FastGaussQuadrature.gausshermite(n)
    HermiteNodes(x), HermiteWeights(w)
end
function gausshermite(::Type{T}, n::Int) where T
    x,w = GaussQuadrature.hermite(T, n)
    HermiteNodes(x), HermiteWeights(w)
end
gausshermite(n::Int) = gausshermite(Float64, n)

struct JacobiWeights{T} <: VectorAlias{T}
    α       ::  T
    β       ::  T
    vector  ::  Vector{T}
end
function gaussjacobi(::Type{Float64}, n::Int, α::Float64, β::Float64)
    x,w = FastGaussQuadrature.gaussjacobi(n, α, β)
    JacobiNodes(α, β, x), JacobiWeights(α, β, w)
end
function gaussjacobi(::Type{T}, n::Int, α::T, β::T) where T
    x,w = GaussQuadrature.jacobi(n, α, β)
    JacobiNodes(α, β, x), JacobiWeights(α, β, w)
end
gaussjacobi(n::Int, α::T, β::T) where T = gaussjacobi(T, n, α, β)
