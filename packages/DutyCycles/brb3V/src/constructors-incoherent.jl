"""

Construct a [`IncoherentDutyCycle{T,U,V}`](@ref) from a constant value (a
converntional number, without `Unitful` dimensions).

"""
function IncoherentDutyCycle{T,U,V}(
    onvalue::NoDimNum
) where {T<:Number, U<:Real, V<:NoDimNum}
    _assertUV(U, V)
    return IncoherentDutyCycle{T,U,V}(
        _infinity(T),
        [one(U)],
        [onvalue]
    )
end
IncoherentDutyCycle{T,U,V}(
    v::Unitful.DimensionlessQuantity
) where {T<:Number, U<:Real, V<:NoDimNum} =
    IncoherentDutyCycle{T,U,V}(convert(V, v / Unitful.unit(v)))


# Construct a `IncoherentDutyCycle{T,U,V}` from one with different
# underlying types. This is required for type conversion (and hence
# for type promotion, too).
function IncoherentDutyCycle{T,U,V}(
    d::IncoherentDutyCycle{T2,U2,V2}
) where {  
    T<:Number,U<:Real,V<:NoDimNum,T2<:Number,U2<:Real,V2<:NoDimNum
}
    return IncoherentDutyCycle{T,U,V}(
        d.period,
        Vector{U}(d.fractionaltimes),
        Vector{V}(d.values)
    )
end

"""

Turn a [`CoherentDutyCycle{T,U,V}`](@ref) into an
[`IncoherentDutyCycle{T,U,V}`](@ref). Note that a suitable type `T`
for the period (one that can store infinity such as a `Rational` or
`AbstractFloat`) must be provided that may differ from the `T` used
for the CoherentDutyCycle, as that also permits `Integer` types for
the period that are not supported by `IncoherentDutyCycle{T,U,V}`.

Note: This is not as useful as the method [`incoherent!`](@ref) which
      has the advantage of retaining more information and hence more
      utility.

"""
function IncoherentDutyCycle{T,U,V}(
    d::CoherentDutyCycle{T2,U2,V2}
) where {T<:Union{Rational,AbstractFloat},U,V, T2,U2,V2}
    return IncoherentDutyCycle{T, U, V}(
        _infinity(convert(T, d.period)),
        convert(Vector{U}, d.fractionaldurations),
        convert(Vector{V}, d.values)
    )::IncoherentDutyCycle{T, U, V}
end
