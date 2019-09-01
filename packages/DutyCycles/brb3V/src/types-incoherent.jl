"""

The concrete, parametrized type for an
[`AbstractIncoherentDutyCycle{T,U,V}`](@ref). It uses the same type
parametrization as [`CoherentDutyCycle{T,U,V}`](@ref).

"""
mutable struct IncoherentDutyCycle{T,U,V} <:
    AbstractIncoherentDutyCycle{T,U,V}
    # the (not well-defined) period, which will hence always be an
    # "atypical" number, namely inf or NaN
    period :: T
    # Normalized duration of each of the piece-wise defined step
    # functions that make up DutyCycle. The normalization is such that
    # sum(durations) == one(T) and multiplication by period gives the
    # total duration.
    fractionaltimes :: Vector{U}
    # values[i] is the dutycycle's value corresponding to
    # totalfractionaldurations[i]
    values :: Vector{V} 
    # possible future extension (To Do: Weight Pro and Contra)
    #shortestspike :: Vector{T}
end
