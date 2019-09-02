module HyperbolicPlane

using LinearFractionalTransformations, Plots, SimpleDrawing, AbstractLattices

export HObject, HPlane, equality_threshold

import Base: getindex, setindex!, isequal, length, ==, show, adjoint, -, in, +
import Base: angle, in, issubset
import AbstractLattices: ∨, ∧, dist

# this is faster than `abs(z)`
_mag(z::Number)::Real = real(z*z')

abstract type HObject end


THRESHOLD = 100   # Global default threshold = THRESHOLD*eps(1.0)


"""
`equality_threshold(val)` sets the "sloppiness" for equality checking.
The default value is 100. In general, two objects are equal if their
stored values are within `val * eps(1.0)`.

Calling `equality_threshold()` with no arguments returns the current
value.
"""
function equality_threshold()
    return THRESHOLD
end
function equality_threshold(newthresh::Real)
    global THRESHOLD = abs(newthresh)
end

setindex!(X::T, val, key::Symbol) where T<:HObject = setindex!(X.attr, val, key)
getindex(X::T, key) where T<:HObject = getindex(X.attr, key)


struct HPlane <: HObject
    attr::Dict{Symbol,Any}
    function HPlane()
        HP = new(Dict{Symbol,Any}())
        set_color(HP)
        set_thickness(HP)
        set_line_style(HP,:dot)
        return HP
    end
end

HPlane(X::HObject) = HPlane()   # copy constructor

(==)(A::HPlane, B::HPlane) = true
show(io::IO, A::HPlane) = print(io,"HPlane()")



include("point.jl")
include("segment.jl")
include("line.jl")
include("ray.jl")
include("triangle.jl")
include("polygon.jl")
include("circle.jl")
include("regular.jl")
include("horocycle.jl")

# straight things
HLinear = Union{HSegment,HLine,HRay}
# Round, fillable things
HRound  = Union{HPlane,HCircle,Horocycle}

export HLinear, HRound

include("meet.jl")
include("triangulate.jl")
include("container.jl")
include("tesselation.jl")


include("isometry.jl")
include("attributes.jl")
include("drawing.jl")

end #end of module
