module VaxData

export AbstractVax, VaxInt, VaxFloat

abstract type AbstractVax <: Real end
abstract type VaxInt <: AbstractVax end
abstract type VaxFloat <: AbstractVax end

include("constants.jl")
include("vaxints.jl")
include("vaxfloatf.jl")
include("vaxfloatd.jl")
include("vaxfloatg.jl")

function Base.read(s::IO, T::Union{Type{VaxInt16},Type{VaxInt32},Type{VaxFloatF},Type{VaxFloatD},Type{VaxFloatG}})
    return read!(s, Ref{T}(0))[]::T
end

function Base.promote(x::T, y::T) where T <: AbstractVax
    Base.@_inline_meta
    px, py = Base._promote(x, y)
    Base.not_sametype((x,y), (px,py))
    px, py
end
function Base.promote(x::T, y::T, z::T) where T <: AbstractVax
    Base.@_inline_meta
    px, py, pz = Base._promote(x, y, z)
    Base.not_sametype((x,y,z), (px,py,pz))
    px, py, pz
end
function Base.promote(x::T, y::T, z::T, a::T...) where T <: AbstractVax
    p = Base._promote(x, y, z, a...)
    Base.not_sametype((x, y, z, a...), p)
    p
end

# Define common arithmetic operations (default for two of the same unknown number type is to no-op error)
# Promotion rules are such that the promotion will always be to a valid IEEE number type,
# even in the case of two identical AbstractVax types
for op in [:+, :-, :*, :/, :^, :<, :<=]
    @eval(begin
        Base.$op(x::T, y::T) where {T<:AbstractVax} = ($op)(promote(x,y)...)
    end)
end

end # module
