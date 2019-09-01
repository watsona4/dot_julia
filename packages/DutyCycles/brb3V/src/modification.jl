"""

This method takes a DutyCycle and uncorrelates its period from all
other periods of other DutyCycles. This effectively turns it into an
incoherent DutyCycle as it then behaves incoherently with regard to
all other DutyCycles except that it retains its type (if it is a
[`CoherentDutyCycle{T,U,V}`](@ref), it remains one with associated period and
phase information although the underlying type for the period may
change).

"""
incoherent(d::AbstractDutyCycle{T,U,V}) where {T,U,V} =
    _make_incoherent(d; modify=false)
incoherent(n::Number) = _extractnondutycycle(n) *
    _make_incoherent(
        _extractdutycycle(n; force = true);
        modify=false
    )

"""

The in-place variant of [`incoherent`](@ref).

"""
incoherent!(d::AbstractDutyCycle{T,U,V}) where {T,U,V} =
    _make_incoherent(d; modify=true)
incoherent!(n::Number) = _extractnondutycycle(n) *
    _make_incoherent(
        _extractdutycycle(n; force = true);
        modify=true
    )

# Implementation for dutycycles that are already incoherent with
# everything else:
_make_incoherent(
    d::AbstractIncoherentDutyCycle{T,U,V};
    modify::Bool
) where {T,U,V} = modify ? d : copy(d)
function _make_incoherent(x::Number; modify::Bool)
    period = default_period()
    T = typeof(period)
    U = Float64
    V = typeof(x)
    return IncoherentDutyCycle{T,U,V}(x)
end

# Implementation for coherent dutycycles: Try to retain the nominal
# period and even its uncertainty (if it is not numerically too small
# to ensure incoherence with all other dutycycles), but make the new
# uncertainty be uncorrelated to all other Meaasurements.Measurement
# values.
function _make_incoherent(
    d::CoherentDutyCycle{T,U,V};
    modify::Bool
) where {T,U,V}
    units = Unitful.unit(d.period)
    v = Measurements.value(d.period / units)
    u = Measurements.uncertainty(d.period / units)
    tol = 2sqrt(eps(v))
    if u <= tol
        # zero uncertainty would still lead to coherent interaction
        # with other dutycycles with zero uncertainty, so pick a small
        # value but not so small that it might be lost in floating
        # point inaccuracies
        u = tol
    end
    # essentially the old period, with a new uncertainty (uncorrelated
    # to any other periods or phases!) that won't be lost in machine
    # precision when comparing it to the period's value
    newperiod = Measurements.measurement(v, u) * units
    U2 = typeof(newperiod)
    if modify && U2 == U
        d.period = newperiod
        return d
    end
    return CoherentDutyCycle(
        newperiod, d.fractionaldurations, d.values
    )
end
