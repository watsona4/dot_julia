"""

Construct a `CoherentDutyCycle` that switches between a maximum value,
passed as first argument, and zero. The optional second argument
specifies the dutycyle (the fraction of a period during which the
maximum value is attained). The next optional period specifies a duty
cycle; a global default value (corresponding to 50 Hz, the power grid
freuqency in Europe, plus a small uncertainty) is used if it is not
given explicitly.

"""
#function CoherentDutyCycle(
#    onvalue::V,
#    duty::U = default_dutycycle(),
#    period::T = default_period(onvalue, duty),
#    phase::U = default_fractional_phase(onvalue, duty, period)
#) where {
#    T<:Number, U<:Real, V<:NoDimNum
#}
#    U2 = _promote_type_U(U)
#    CoherentDutyCycle{T,U2,V}(
#        onvalue,
#        convert(U2, duty);
#        period = period,
#        phase = convert(U2, phase)
#    )
#end
# construct a CoherentDutyCycle from a Unitful.DimensionlessQuantity
function CoherentDutyCycle{T,U,V}(onvalue::NoDimNum) where {
    T<:Number, U<:Real, V<:NoDimNum
}
    _assertUV(U, V)
    period = default_period(T, onvalue)
    return CoherentDutyCycle{T,U,V}(
        period,
        Vector{U}([one(U)]),
        Vector{V}([onvalue])
    )
end
CoherentDutyCycle{T,U,V}(
    v::Unitful.DimensionlessQuantity
) where {T<:Number, U<:Real, V<:NoDimNum} =
    CoherentDutyCycle{T,U,V}(convert(V, v / Unitful.unit(v)))

"""

Construct a CoherentDutyCycle from arguments of the type `duration =>
value`. The types involved are determined by the first pair and there
must be at least one. Note the warning at the analogous but more
general [`cycle`](@ref) method that can accept units in the values.

"""
function CoherentDutyCycle(
    pair1::Pair{T1,V1}, pairs::Pair{TN}{VN}...
) where {T1<:Number,V1<:Real,TN<:Number, VN<:Number}
    period, fractionaldurations, values =
        _handlepairs(pair1, pairs...)
    T = typeof(period)
    U = typeof(fractionaldurations[1])
    V = typeof(values[1])
    return CoherentDutyCycle{T,U,V}(
        period,
        fractionaldurations,
        values
    )
end

# Construct a `CoherentDutyCycle{T,U,V}` from one with different
# underlying types. This is required for type conversion (and hence
# for type promotion, too).
function CoherentDutyCycle{T,U,V}(
    d::CoherentDutyCycle{T2,U2,V2}
) where {  
    T<:Number,U<:Real,V<:NoDimNum,T2<:Number,U2<:Real,V2<:NoDimNum
}
    return CoherentDutyCycle{T,U,V}(
        convert(T, d.period),
        Vector{U}(d.fractionaldurations),
        Vector{V}(d.values)
    )::CoherentDutyCycle{T,U,V}
end

