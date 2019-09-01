"""

The concrete, parametrized type for an
[`AbstractCoherentDutyCycle{T,U,V}`](@ref). It is parametrized on type
`T` for temporal values (for the total period, can optionally include
units), on type `U` which is the same type without units (for phases)
and on type `V` (for values). Note that T and V must not include
units; the way to get units attached to a DutyCycle is to use it as
the underlying type of a `Unitful.Quantity` rather than the other way
around.

"""
mutable struct CoherentDutyCycle{T,U,V} <:
    AbstractCoherentDutyCycle{T,U,V}
    # The period can have a unit, can be (based on) a rational or
    # integer (or float).
    period :: T
    # Normalized duration of each of the piece-wise defined step
    # functions that make up DutyCycle. The normalization is such that
    # sum(durations) == one(T).
    fractionaldurations :: Vector{U}
    # values, each corresponding to a fractional duration that is
    # given by the element of fractionaldurations at the same index
    values :: Vector{V} 
end
