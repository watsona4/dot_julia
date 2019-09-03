using Compat.Dates
using Missings

using Unitful: unit

import Base: *, convert
import Compat: round
import Compat.Statistics: mean
import Unitful: ustrip


# Helper functions
round(x::AbstractArray{<:Quantity}, r::Int) = round(ustrip(x), r) * unit(eltype(x))
round(x::T, r::Int) where {T<:Quantity} = round(ustrip(x), r) * unit(x)

mean(x::AbstractArray{<:Quantity}, r::Int) = mean(ustrip(x), r) * unit(eltype(x))

"""
    asqtype(x::T) where {T<:Unitful.Units} -> Type

A helper function to convert from the "dimensions" of a Unitful quantity to the "quantities",
as they are treated separately.
"""
asqtype(x::T) where {T<:Unitful.Units} = typeof(1.0*x)


# Handle working with  Missings
const UnitfulMissing = Union{<:Unitful.Quantity, Missings.Missing}

*(y::Missings.Missing, x::T) where {T<:Unitful.FreeUnits} = y
ustrip(x::Missings.Missing) = x

"""
    fustrip(x::Array{T}) where {T<:Any} = Array

Operation to strip the units an Parametric Array{T} Type. Needed for operating on DataFrames?
"""
fustrip(x::Array{T}) where {T<:Any} = map(t -> ustrip(t), x)


# Handle working with `Period`s
*(x::Unitful.Units, y::Period) = *(y, x)
*(x::Period, y::Unitful.Units) = convert(y, x)
function convert(a::Unitful.Units, x::Period)
    sec = Dates.value(Dates.Second(x))
    uconvert(a, (sec)u"s")
end

# Methods to drop
# Exist to test that (offsets)u"hr" should work the same way
dt2umin(t::AbstractArray{Dates.Minute}) = Dates.value.(t).*u"minute"
