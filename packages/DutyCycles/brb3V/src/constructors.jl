"""

Construct a [`CoherentDutyCycle{T,U,V}`](@ref) from arguments of the
type `duration => value`.

$(SIGNATURES)

!!! warning
    If you specify durations e.g. in seconds, the resulting
    CoherentDutyCycle will act incoherently with those having the
    default period: To obtain coherence with them, you have to derive
    the durations from [`default_period`](@ref) or change that
    default. This should not be a problem in practice, however,
    because the default_period is applied, by default, only to numbers
    that are constant in time.

!!! info "To Do"
    Format the other method documentation (docstrings) in the
    recommended way: A single, short sentence, then the signature,
    then an optional paragraph or more of explanation, hints,
    warnings, etc. See
    [julia's documentation on documentation](https://docs.julialang.org/en/v1/manual/documentation/index.html).

"""
function cycle(
    pairs::Pair...
)
    period, fractionaldurations, values, units =
        _handlepairswithpossibleunits(pairs...)
    T = typeof(period)
    U = typeof(fractionaldurations[1])
    @assert(Unitful.dimension(U) == Unitful.NoDims)
    V = typeof(values[1])
    return units * CoherentDutyCycle{T,U,V}(
        period, fractionaldurations, values
    )
end

"""

Construct a [`CoherentDutyCycle{T,U,V}`](@ref) from a given dutycycle value,
with optional, named keyword arguments `avg`, `offvalue`, `onvalue`,
`period` and `phase`.

$(SIGNATURES)

If an `onvalue` is supplied, it overrules any supplied `avg` (average)
value. By default it averages to the floating point value `1.0`, with
no units, with a zero `offvalue`.

!!! info "To Do"
    Add optional parameters `ontime` and `offtime` (and try calculating
    the `period` from the sum of these before defaulting to
    [`default_period`](@ref)).

It is possible to use this function without specifying a duty cycle
(which normally constitutes the first argument). Note that you have to
make the lack of it explicit by starting the argument list with a
semicolon. Then the keyword `avg` for the average value is no longer
optional and determines the duty cycle together with the optional
keyword arguments `onvalue` and `offvalue`.

"""
dutycycle(duty::Unitful.DimensionlessQuantity; kwargs...) =
    dutycycle(uconvert(Unitful.NoUnits, duty); kwargs...)
function dutycycle(
    duty::Real;
    avg = nothing,
    offvalue = nothing,
    onvalue = _firstactual(avg, 1.0) / duty -
        _firstactual(offvalue, zero(_firstactual(avg, 0)), 0),
    period = default_period(onvalue),
    phase::Real = 0
)
    actualoffvalue = _firstactual(offvalue, zero(onvalue))
    if avg !== nothing
        if avg ≉ actualoffvalue + (onvalue - actualoffvalue) * duty
            @warn string(
                "constructing a dutycycle with an average ",
                "that differs from the avg parameter ",
                "because of other supplied parameters ",
                "(onvalue, offvalue)."
            ) duty avg offvalue onvalue period phase
        end
    end
    if duty < zero(duty) || duty > one(duty)
        throw(DomainError("dutycycle may only range from 0 to 1"))
    end    
    local d
    if duty == zero(duty)
        onvalue = actualoffvalue
        duty = one(duty)
    end
    if duty < one(duty)
        d = cycle(
            (duty*period) => onvalue,
            (one(duty)-duty)*period => actualoffvalue
         )
    else
        d = cycle(period => onvalue)
    end
    if phase == zero(phase)
        return d
    end
    return phaseshift!(d, phase)
end
function dutycycle(
    ;
    avg,
    onvalue = one(avg) * unit(avg),
    offvalue = zero(onvalue),
    kwargs...
)
    duty_numerator = uconvert(NoUnits, (avg - offvalue) / unit(avg))
    duty_denominator = uconvert(
        NoUnits,
        (onvalue - offvalue) / unit(avg)
    )
    if duty_numerator isa Union{Integer, Rational}
        if duty_denominator isa Union{Integer, Rational}
            # we can (and, for Integers, must) use an exact fraction
            # (lest the normal division leads to an InexactError for
            # Integers)
            return dutycycle(
                duty_numerator // duty_denominator,
                onvalue=onvalue,
                offvalue=offvalue,
                kwargs...
            )
        end
    end
    # default to an inexact dutycycle fraction
    dutycycle(
        duty_numerator / duty_denominator;
        onvalue=onvalue,
        offvalue=offvalue,
        kwargs...
    )
end
