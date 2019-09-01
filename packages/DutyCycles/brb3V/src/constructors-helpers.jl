# helper methods only used in files constructor*.jl; all other helpers
# should go into file helpers.jl
@inline function _assertUV(U, V)
    @debug begin
        # the intention is for Unitful.Quantity to wrap a DutyCycle,
        # not the other way around, so assert that did not happen,
        # even _if_ the type restrictions for U and V are ever lifted
        @assert !(V <: Unitful.AbstractQuantity)
        @assert !(U <: Unitful.AbstractQuantity)
        "asserted type U=$U, and V=$V for new DutyCycle"
    end
    nothing
end
function _handleperiod(period::Number)
    # check period for DomainErrors
    if period <= zero(period)
        throw(DomainError("period must be positive"))
    end
    return period
end
function _handleincoherentperiod(period::Number)
    if !isinf(period) && !isnan(period)
        throw(DomainError(
            "period of IncoherentDutyCycle must be infinite or NaN"
        ))
    end
    period
end
# promote the type U used for unitless numbers, namely fractions of a
# period such as fractionaldurations and fractionaltimes, based on the
# naively chosen types T, U, V (for times, unitless fractions, and
# values, respectively).
_promote_type_U(U::Type{TU}) where {TU<:Integer} = Rational{TU}
function _promote_type_U(U::Type{TU}) where {TU<:Real}
    @assert !(U isa Integer)
    return TU
end
@inline function _handledutycycle(duty::Real)
    # check dutycycle for DomainErrors
    if duty < zero(duty) || duty > one(duty)
        throw(DomainError(
            "dutycycle must be between zero and one inclusive"
        ))
    end
    return duty
end
function _handlepairs(
    pairs::Pair{<:T}{<:V}...
) where {T<:Number, V<:NoDimNum}
    if length(pairs) < 1
        onvalue = 1.0
        duty = 1//1
        period = default_period(onvalue, duty)
        pairs = [
            duty*period => onvalue,
            (one(duty) - duty) * period => 0
        ]
        @warn (
            "Missing duration => value pairs, defaulting to"
        ) pairs
    end
    durations, values = _unzippairs(pairs...)
    period = _handleperiod(sum(durations))
    if durations[1] isa Integer
        # use Rational numbers for fractions of a cycle
        return period, _handlefractionaldurations(
            durations .// period
        ), values
    end
    return period, _handlefractionaldurations(
        durations ./ period
    ), values
end
function _handlepairswithpossibleunits(
    pairs::Pair{<:T}{<:V}...
) where {T<:Number, V<:Number}
    if length(pairs) < 1
        period, fractionaldurations, values = _handlepairs(pairs...)
        return period, fractionaldurations, values, one(values[1])
    end
    durations, values = _unzippairs(pairs...)
    units = Unitful.unit(values[1])
    period = _handleperiod(sum(durations))
    if _isrational(period)
        # use a Rational number type for phases
        return period, _handlefractionaldurations(
            durations .// period
        ), values ./ units, units
    end
    return period, _handlefractionaldurations(
        durations ./ period
    ), values ./ units, units
end
# Note: The following method is not type-stable :-(
function _handlefractionaldurations(fds::Vector{T}) where {
    TT, T<:Measurements.Measurement{TT}
}
    tol = sqrt(eps(one(fds[1])))
    if _exists(fd -> Measurements.uncertainty(fd) > tol, fds)
        return fds
    end
    # there is no numerically significant uncertainty in any of the
    # fds, so choose a type that has no uncertainty
    return Vector{TT}([Measurements.value(fd) for fd in fds])
end
_handlefractionaldurations(fds::Vector{<:Real}) = fds
