include("Ray.jl")
include("Arc.jl")
include("Line.jl")
include("IntervalCurve.jl")

# sort

isless(d1::IntervalOrSegment{T1},d2::Ray{false,T2}) where {T1<:Real,T2<:Real} = d1 ≤ d2.center
isless(d2::Ray{true,T2},d1::IntervalOrSegment{T1}) where {T1<:Real,T2<:Real} = d2.center ≤ d1


## set minus
Base.setdiff(d::Union{AbstractInterval,Segment,Ray,Line}, ptsin::UnionDomain{AS}) where {AS <: AbstractVector{P}} where {P <: Point} =
    affine_setdiff(d, ptsin)

Base.setdiff(d::Union{AbstractInterval,Segment,Ray,Line}, ptsin::WrappedDomain{<:AbstractVector}) = 
    affine_setdiff(d, ptsin)

Base.setdiff(d::Union{AbstractInterval,Segment,Ray,Line}, ptsin::AbstractVector{<:Number}) = 
    ApproxFunBase._affine_setdiff(d, ptsin)

Base.setdiff(d::Union{AbstractInterval,Segment,Ray,Line}, ptsin::Number) = 
    ApproxFunBase._affine_setdiff(d, ptsin)    