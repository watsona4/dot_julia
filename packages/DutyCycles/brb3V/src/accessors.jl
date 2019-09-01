"""

Return the period of a DutyCycle.

"""
function period(d::AbstractDutyCycle) end
function period(n::Number)
    d = _extractdutycycle(n)
    if d isa AbstractDutyCycle
        return period(d)
    end
    return default_period(n)
end
period(d::AbstractIncoherentDutyCycle{T,U,V}) where {T,U,V} =
    _infinity(T)
period(d::CoherentDutyCycle) = d.period

"""

Return the fundamental frequency of a DutyCycle. It is the inverse of
its period.

"""
fundamental_frequency(n::Number) = inv(period(n))

"""

Return the values assumed by a DutyCycle during a period.

!!! note
    For a DutyCycle that resulted from an operation involving
    incoherent DutyCycle objects, there is no guarantee that the
    values returned will ever occur in that specific order. In fact,
    they typically will never do so.

"""
function values(::AbstractDutyCycle) end
values(d::CoherentDutyCycle) = d.values
values(d::IncoherentDutyCycle) = d.values

"""

Return the fractional (per cycle) durations associated with the
`values`[@ref] assumed by a DutyCycle, in the same order that they are
returned, such that `fractionaldurations(d)[i]` corresponds to
`values(d)[i]` and `zip(fractionaldurations(d), values(d))` makes
sense for a DutyCycle `d`.

"""
function fractionaldurations(::AbstractDutyCycle) end
fractionaldurations(d::CoherentDutyCycle{T,U,V}) where {T,U,V} =
    d.fractionaldurations
fractionaldurations(d::AbstractIncoherentDutyCycle) =
    repeated(missing, length(d.values))

"""

Return the total fractional (per cycle) time associated with the
`values`[@ref] assumed by a DutyCycle, in the same order that they are
returned. A total fractional duration is the sum of durations during
which a given value occurs. Note that the duty cycle may not assume
this value for any given length of time, as an incoherent DutyCycle
may (and, in general, will) vary its value faster than this.

"""
function fractionaltimes(::AbstractDutyCycle) end
fractionaltimes(
    d::CoherentDutyCycle{T,U,V}
) where {T,U,V} = fractionaldurations(d)
fractionaltimes(d::IncoherentDutyCycle) =
    d.fractionaltimes

"""

Return the durations associated with the `values`[@ref] assumed by a
coherent DutyCycle, in the same order that they are returned, such
that `durations(d)[i]` corresponds to `values(d)[i]` and
`zip(durations(d), values(d))` makes sense for a DutyCycle `d`. For an
incoherent DutyCycle, return a vector of missings of the appropriate
length.

"""
function durations(::AbstractDutyCycle) end
durations(d::AbstractCoherentDutyCycle) =
    fractionaldurations(d) .* period(d)
durations(d::AbstractIncoherentDutyCycle) =
    repeated(missing, length(d.values))
