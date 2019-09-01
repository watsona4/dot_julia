# file helpers.jl

"""

Return the DutyCycle contained in a Number, if there is one, and the
`Int` 1 if there is none.

"""
_extractdutycycle(d::AbstractDutyCycle; force::Bool = false) = d
_extractdutycycle(q::Q; force::Bool = false) where {
    Q<:Unitful.AbstractQuantity{<:AbstractDutyCycle}{D}{U} where {D,U}
} = _extractdutycycle(q / Unitful.unit(q))
function _extractdutycycle(n::Number; force::Bool = false)
    # assert that specialized dispatch worked
    @assert !(n isa Unitful.AbstractQuantity)
    @assert !(n isa AbstractDutyCycle)
    # are we forced to return a dutycycle, even if that involves
    # creating one just to be able to deliver it?
    if force
        T = typeof(default_period(1))
        return CoherentDutyCycle{T}{Rational{Int}}{Int}(1)
    end
    return 1
end
_extractdutycycle(::Missing; force::Bool = false) =
    _extractdutycycle(0; force = force)

"""

Return whatever multiplicative element is not a DutyCycle in a number
(e.g. units) or the integer `1` if there is no such thing.

"""
_extractnondutycycle(d::AbstractDutyCycle) = 1
_extractnondutycycle(q::Q) where {
    Q<:Unitful.AbstractQuantity{T}{D}{U} where {T<:AbstractDutyCycle,D,U}
} = Unitful.unit(q)
_extractnondutycycle(q::Q) where {
    Q<:Unitful.AbstractQuantity{T}{D}{U} where {T<:Number,D,U}
} = q
_extractnondutycycle(n::Number) = n
_extractnondutycycle(::Missing) = missing

"""

Return true if there is at least one element in the collection passed
as argument. Prepend a predicate function to only return true if there
is at least one element for which it is true.

"""
_exists(coll) = (length(coll) > 0)
_exists(predicate, coll) = findfirst(predicate, coll) !== nothing

# Test if a number is rational (inclusive, in the sense of covering
# interegers, too) or has an underlying type that is rational). The
# result can be used to define the best way to perform a division
# between two numbers of that type (use the exact division operator //
# if the result is true and the normal division operator / otherwise).
_isrational(n::Number) = _isrational(typeof(n))
function _isrational(n::Type{T}) where {T<:Number}
    local ratio
    try
        ratio = one(n) // 13
    catch ex
        if ex isa MethodError
            return false # type has no exact division operator
        else
            rethrow(ex)
        end
    end
    if 13 * ratio == one(n)
        return true # exact number type
    end
    @error "Expected equality or MethodError" 13ratio one(n)
    error("Expected $(13ratio)==$one(n) or MethodError")
end
# To Do: Dispatch on specific types to improve performance (by
# avoiding to rely on catching errors)

# we need specializations for unitful quantities because the above
# somehow omits the unit; the following obsolte specializations for
# _infinity could serve as a template
#
#_infinity(V::Type{<:Unitful.AbstractQuantity{T,D,U}}) where {
#    T<:Number,D,U
#} = unit(V) * one(T) / zero(T)
#_infinity(::Type{<:Unitful.AbstractQuantity{T,D,U}}) where {
#    T<:Integer,D,U
#} = unit(Unitful.AbstractQuantity{T,D,U}) * one(T) // zero(T)
#_infinity(::Type{<:Unitful.AbstractQuantity{T,U,D}}) where {
#    T<:Rational,D,U
#} = unit(Unitful.AbstractQuantity{T,D,U}) * one(T) // zero(T)
#_infinity(::Type{T}) where {T<:Integer} = one(T) // zero(T)
#_infinity(::Type{T}) where {T<:Rational} = one(T) // zero(T)
# To Do: Check if we need a specialized dispatch for Unitful.Quantity
#        (one(T) might not be defined for it)

# return infinity of the type specified by type or value
#_infinity(::Type{T}) where {T<:Number} = one(T) / zero(T)
function _infinity(::Type{T}) where {T<:Number}
    # Note that, at least currently, Unitful returns inverse units for
    # one(T) / zero(T), so we have to correct this by multiplying with
    # unit(T)^2
    if _isrational(T)
        return unit(T)^2 * (one(T) // zero(T))
    end
    return unit(T)^2 * (one(T) / zero(T))
end
_infinity(v::T) where {T<:Number} = _infinity(typeof(v))

# return true if and only if the given type includes support for an
# uncertainty quality
_has_known_uncertainty_support(v::Number) =
    _has_known_uncertainty_support(typeof(v))
# generic solution
function _has_known_uncertainty_support(::Type{T}) where {T<:Number}
    # Note that this only works if the uncertainty is provided by
    # Measurements (or perhaps also if an external library properly
    # overwrites/amends the method Base.:* or Measurements.Measurement
    # that we use?).  However, since there is no AbstractMeasurement
    # type, it may not be possible to do better.
    oneunit = one(T) * Unitful.unit(T)
    # assert that we really got the right unit (one(t) might get
    # "fixed" from its current definition of returning something
    # dimensionless...)
    @assert Unitful.unit(oneunit) == Unitful.unit(T)
    if typeof(oneunit * Measurements.measurement(1,1)) == T
        # type T accomodates uncertainty without being promoted to a
        # different type, so there is uncertainty support in T
        return true
    end
    return false
end
# cases with explicitly known support for modeling uncertainties
#_has_known_uncertainty_support(::Type{<:Measurements.Measurement}) =
#    true
#_has_known_uncertainty_support(::Type{
#    <:Unitful.AbstractQuantity{Measurements.Measurement{T}}{D}{U}
#}) where {T,D,U} = true
# cases with explicitly known lack of support for uncertainties
#_has_known_uncertainty_support(::Type{<:Integer}) = false
#_has_known_uncertainty_support(::Type{<:Rational}) = false

# extract the underlying type T from a Unitful.AbstractQuantity{T,U,D}
_extract_T_from_Unitful_AbstractQuantity(
    v::Unitful.AbstractQuantity
) = typeof(v)
_extract_T_from_Unitful_AbstractQuantity(
    ::Type{<:Unitful.AbstractQuantity{T,U,D}}
) where {T,U,D} = T

# remove uncertainty from x, if the desired type T requires it; also
# round or rationalize, and also change units and even dimensions;
# warn when doing things like chaning dimensions, changing the value
# by rounding, or omitting uncertainty.
function convert_warn(
    ::Type{T}, x::U, warnprefix::AbstractString=repr(x)
) where {T<:Number,U<:Number}
    if Unitful.dimension(T) == Unitful.dimension(x)
        return convert(
            T,
            _convert_warn_samedimension(T, x, warnprefix)
        )
    end
    # first remove all dimensions (by stripping units away) after
    # conversion to preferred (and user configurable!) units
    pu = Unitful.upreferred(Unitful.unit(x))
    y = x / pu
    # then add new units, converting from preferred units to
    # effectively have converted by a suitable combination of base
    # units, i.e. by adding and removing power of the units returned
    # by upreferred
    u = Unitful.unit(T)
    if u != Unitful.NoUnits
        # if we have to add any units (rather than just stripping them),
        # warn about that specifically
        @warn string(
            warnprefix,
            ": dimensions given that differ from the input ",
            "more than just by stripping its units"
        )
    else
        @warn string(
            warnprefix,
            ": dimensions given that differ from the input"
        )
    end
    try
        return convert(T, _convert_warn_samedimension(
            T,
            y * Unitful.uconvert(upreferred(u), 1u),
            warnprefix
        ))::T
    catch ex
        @error "data" T x y y*Unitful.uconvert(upreferred(u), 1u) _convert_warn_samedimension(
            T,
            y * Unitful.uconvert(upreferred(u), 1u),
            warnprefix
        )
        rethrow(ex)
    end
end
# helper for the method above; note that it does not necessarily
# return a number of the specified type but rather one that should be
# convertible to it
function _convert_warn_samedimension(
    ::Type{T}, x::X, warnprefix::AbstractString=repr(x)
) where {
    T<:Number,X<:Number
}
    # expect matching dimensions (both are times, or both are lengths,
    # etc.); asert that this is the case for ease of debugging
    @assert Unitful.dimension(T) == Unitful.dimension(x)
    u = unit(T)
    z = Unitful.uconvert(u, x)
    if _has_known_uncertainty_support(T)
        return z
    end
    y = DutyCycles.measurementvalue_warn(z / u, warnprefix)
    @assert(Unitful.dimension(y) == Unitful.NoDims)
    @assert(Unitful.unit(y) == Unitful.NoUnits)
    # we must check for the underlying type of T to process y
    UT = T
    if UT <: Unitful.AbstractQuantity
        UT = _extract_T_from_Unitful_AbstractQuantity(T)
    elseif UT <: Unitful.Quantity
        @assert Unitful.Quantity <: Unitful.AbstractQuantity
        error("unreachable statement")
    end
    if UT<:Integer
        return (DutyCycles.roundavoidingzero_warn(
            UT,
            y,
            warnprefix
        ) * u)
    elseif UT<:Rational
        return (rationalize(
            typeof(numerator(zero(UT))),
            y
        ) * u)
    end
    return (y * u)
end

# access the value of a measurement, warning if this discards any
# uncertainty information
#
# To Do: Could be useful on its own, hence without leading "_"
function measurementvalue_warn(
    m::Measurements.Measurement,
    warnprefix::AbstractString=repr(m)
)
    value = Measurements.value(m)
    uncertainty = Measurements.uncertainty(m)
    if uncertainty != zero(m)
        ru = uncertainty / value
        @warn string(
            warnprefix,
            ": adding coherence by removing rel. uncertainty of $ru"
        )
    end
    @assert !_has_known_uncertainty_support(value)
    return value
end
function measurementvalue_warn(
    m::Number,
    warnprefix::AbstractString=""
)
    @assert !(m isa Measurements.Measurement) # assert specialization
    return m
end

# round, not returning zero if the input is nonzero, warning if this
# changes the value
# To Do: Could be useful on its own, hence without leading "_"
function roundavoidingzero_warn(
    ::Type{T},
    x::NoDimNum,
    warnprefix::AbstractString=repr(x)
) where {
    T<:Integer
}
    i::T = round(T, x)
    if i == zero(i) && x != zero(x)
        i = x >= 0 ? one(T) : -one(T)
    end
    if i != x
        @warn string(
            warnprefix,
            ": rounding (avoiding zero) changed the value"
        )
    end
    return i::T
end

# return the first argument, unless it is nothing or missing, then
# return the first argument for which that is not the case
#function _firstactual(primary, secondary...)
#    @assert primary !== nothing
#    @assert primary !== missing
#    primary
#end
#_firstactual(primary::Nothing, secondary...) =
#    _autodefault(secondary...)
#_firstactual(primary::Missing, secondary...) =
#    _autodefault(secondary...)
#_firstactual(primary) = primary
_firstactual(args...) = first(coalesce([
    arg === nothing ? missing : arg for arg in args
]...))

# unzip, not a complete solution, just for the requirements of this
# package
#
# To Do: Base.unzip might become part of a future version of julia,
#        see https://github.com/JuliaLang/julia/issues/13942 and
#        https://github.com/JuliaLang/julia/pull/30987, so check if it
#        is defined and then use that instead
#
# To Do: Investigate the issue of type stability when using this
#        method.
function _unzippairs(pairs::Pair...)
    N = length(pairs)
    if N == 0
        return Vector{Number}(undef, 0), Vector{Number}(undef, 0)
    end
    # first determine a suitable type
    Ta, Tb = typeof(pairs[1][1]), typeof(pairs[1][2])
    for i = 2:N
        Ta2, Tb2 = typeof(pairs[i][1]), typeof(pairs[i][2])
        if Ta2 != Ta
            Ta = promote_type(Ta, Ta2)
        end
        if Tb2 != Tb
            Tb = promote_type(Tb, Tb2)
        end
    end
    as = Vector{Ta}(undef, N)
    bs = Vector{Tb}(undef, N)
    for i = 1:N
        as[i], bs[i] = pairs[i]
    end
    return as, bs
end

"""

Convenience function to assert that all internal relationships in a
DutyCycle are correct. It is not exported because it is not expected
that a normal user will need to check these, but included to allow
such a test if it is needed (e.g. in unit tests or bug reports).

"""
function check(
    d::CoherentDutyCycle{T,U,V}
) where {T<:Number,U<:Real,V<:NoDimNum}
    @assert d.period >= zero(T)
    @assert length(d.fractionaldurations) == length(d.values)
    @assert one(U) ≈ sum(d.fractionaldurations)
    for fd in d.fractionaldurations
        @assert fd >= zero(U)
    end
    return d
end
function check(
    d::IncoherentDutyCycle{T,U,V}
) where {T<:Number,U<:Number,V<:Number}
    @assert isinf(d.period) || isnan(d.period)
    @assert length(d.fractionaltimes) == length(d.values)
    @assert one(U) ≈ sum(d.fractionaltimes)
    for ft in d.fractionaltimes
        @assert ft >= zero(U)
    end
    return d
end
check(
    q::Unitful.AbstractQuantity{DutyCycle{DT,DU,DV},QD,QU}
) where {DT<:Number,DU<:Real,DV<:NoDimNum,QD,QU} =
    check(q / unit(q)) * unit(q)
check(q::Number) = q

"""

Helper function to apply a method phase-wise to each value of a
DutyCycle. Not exported.

"""
function applyphasewise(
    f::Function, d::CoherentDutyCycle{T,U,V}
) where {T,U,V}
    return CoherentDutyCycle(
        d.period,
        d.fractionaldurations,
        map(f, d.values)
    )
end
function applyphasewise(
    f::Function, d::IncoherentDutyCycle{T,U,V}
) where {T,U,V}
    return CoherentDutyCycle(
        d.period,
        d.fractionaltimes,
        map(f, d.values)
    )
end
function applyphasewise!(f::Function, d::CoherentDutyCycle)
    for i=1:length(d.values)
        d.values[i] = f(d.values[i])
    end
    return d
end
function applyphasewise!(f::Function, d::IncoherentDutyCycle)
    for i=1:length(d.values)
        d.values[i] = f(d.values[i])
    end
    return d
end

"""

Helper function to apply a binary operator. Not exported.

"""
function applyphasewise(
    operator::Function,
    a::AbstractDutyCycle{T1,U1,V1},
    b::AbstractDutyCycle{T2,U2,V2}
) where {T1,U1,V1, T2,U2,V2}
    V = typeof(operator(zero(V1), zero(V2)))
    U = promote_type(U1, U2)
    coherent = true #iscoherent(a) && iscoherent(b)
    if coherent
        # potentially coherent, depending on period ratio
        periodratio = coherence_ratio(
            period(a),
            period(b);
            maxperiods = MAX_REPETITIONS
        )
        if !isinf(periodratio)
            # coherent case
            T = promote_type(T1, T2)
            return applyphasewise_coherently(
                CoherentDutyCycle{T,U,V},
                operator,
                a,
                b,
                periodratio
            )
        end
    end
    # incoherent case
    newperiod = 1unit(promote_type(T1,T2)) / 0
    T = typeof(newperiod)
    return applyphasewise_incoherently(
        IncoherentDutyCycle{T,U,V},
        operator,
        a,
        b,
        newperiod
    )
end

# treat a and b as incoherent (e.g. with incommensurate periods or no
# fixed phase relationship)
function applyphasewise_incoherently(
    ::Type{IncoherentDutyCycle{T,U,V}},
    operator::Function,
    a::AbstractDutyCycle{T1,U1,V1},
    b::AbstractDutyCycle{T2,U2,V2},
    period::T = 1.0unit(T1) / 0
) where {T,U<:Real,V, T1,U1<:Real,V1, T2,U2<:Real,V2}
    aphases = fractionaltimes(a)
    bphases = fractionaltimes(b)
    aN, bN = length(aphases), length(bphases)
    N = aN * bN
    phases = Vector{U}(undef, N)
    values = Vector{V}(undef, N)
    i = 1
    for ai = 1:aN
        for bi = 1:bN
            phases[i] = aphases[ai] * bphases[bi]
            values[i] = operator(a.values[ai], b.values[bi])
            i += 1
        end
    end
    return IncoherentDutyCycle{T,U,V}(period, phases, values)
end

# treat a and b as coherent (with commensurate periods and a fixed
# phase relationship)
function applyphasewise_coherently(
    ::Type{CoherentDutyCycle{T,U,V}},
    operator::Function,
    a::CoherentDutyCycle{T1,U1,V1},
    b::CoherentDutyCycle{T2,U2,V2},
    periodratio::Rational = coherence_ratio(a.period, b.period)
) where {T,U<:Real,V, T1,U1<:Real,V1, T2,U2<:Real,V2}
    if isinf(periodratio)
        throw(DomainError(
            "incommensurate periods cannot be treated coherently"
        ))
    end
    a_over_b = convert(U, periodratio)
    b_over_a = convert(U, 1 // periodratio)    
    # as: number of repeats of a, bs: num. of rep. of b
    aphases = fractionaldurations(a)
    bphases = fractionaldurations(b)
    aN, bN = length(aphases), length(bphases)
    bs, as = numerator(periodratio), denominator(periodratio)
    period = convert(T, as * a.period) # new period
    phases = Vector{U}(undef, 0)
    values = Vector{V}(undef, 0)
    ai, bi = 1, 1 # indices into a.values and b.values
    Utolerance = _isrational(U) ? zero(U) : sqrt(eps(one(U)))
    # the phases at which indices length(phases), ai, bi become valid
    phase, aphase, bphase = zero(U), zero(U1), zero(U2)
    # the remaining phases for which ai, bi are valid
    rema, remb = aphases[ai], bphases[bi]
    while phase < one(U)
        if rema * bs < remb * as
            # remaining phase rema of a will deplete first
            rem = rema / as
            if rem > Utolerance
                push!(phases, rem)
                push!(values, operator(a.values[ai], b.values[bi]))
            end
            phase += rem
            remb -= rema * a_over_b
            ai = (ai % aN) + 1
            rema = aphases[ai]
        else
            # remaining phase remb of b will deplete first (or tie)
            rem = remb / bs
            if rem > Utolerance
                push!(phases, rem)
                push!(values, operator(a.values[ai], b.values[bi]))
            end
            phase += rem
            rema -= remb * b_over_a
            bi = (bi % bN) + 1
            remb = bphases[bi]
        end
    end
    # phase might end up larger than one(U): subtract the excess
    phases[length(phases)] -= phase - one(U)
    return CoherentDutyCycle{T,U,V}(period, phases, values)
end

"""

Delay a dutycycle by the given phase in units of fractional
cycles. Note that phases can also be supplied in the `Unitful` units
`rad` or `°`. To Do: Implement units using package
`UnitfulAngles`.

!!! warning
    If no units are given, the phase is assumed to be in turns,
    i.e. `1` corresponds to a full cycle, not to `1 radians`. The
    rationale is that this way, exact phases can be represented using
    rational numbers. Do not assume that you can pass a phase in
    radians as you can do with (sensibly defined) trigonometry
    functions!

!!! info "To Do"
    Implement this method.

"""
function phaseshift!(
    d::AbstractDutyCycle{T,U,V}, fractionalphasedelay::Real; warn=true
) where {T<:Number, U<:Real, V<:NoDimNum}
    error("abstract method called")
end
function phaseshift!(
    d::CoherentDutyCycle{T,U,V}, fractionalphasedelay::Real; warn=true
) where {T<:Number, U<:Real, V<:NoDimNum}
    warn && _warnphase(fractionalphasedelay)
    if fractionalphasedelay != zero(U)
        error("phaseshift! unimplemented")
    end
    return d
end
function phaseshift!(
    d::AbstractIncoherentDutyCycle, fractionalphasedelay::Real; warn=true
) where {T<:Number, U<:Real, V<:NoDimNum}
    warn && _warnphase(fractionalphasedelay)
    if fractionalphasedelay != zero(U)
        @warn "phaseshift of an IncoherentDutyCycle has no effect"
    end
    return d
end
phaseshift!(n::Real, fractionalphasedelay::Real) = n
phaseshift!(n::Number, fractionalphasedelay::Real) =
    _extractnondutycycle(n) *
    phaseshift(_extractdutycycle(n), fractionalphasedelay)
function phaseshift!(
    d::AbstractDutyCycle,
    extraphase::Unitful.DimensionlessQuantity
)
    units = Unitful.unit(extraphase)
    if units == Unitful.NoUnits
        # default to units of turns, not radians
        # (for consistency)
        return phaseshift!(d, extraphase / units)
    end
    return phaseshift!(uconvert(UnitfulAngles.Turn, extraphase))
end

"""

See [`phaseshift!`](@ref).

"""
phaseshift(d::Number, fractionalphasedelay::Number) =
    phaseshift!(copy(d), fractionalphasedelay, warn=false)

function _warnphase(phase::Rational) end
function _warnphase(phase::Real)
    # see if by interpreting the phase in radians we can get a ratio
    # no more complicated than breaking an angle down to integer
    # seconds of arc, then warn assuming that might have been meant
    if hascoherence_ratio(phase, 2pi, maxperiods=360*60*60)
        @warn string(
            "It looks like you supplied a phase in radians ",
            "where one in turns (one turn is 2π radians) ",
            "is expected. If that is the case, ",
            "divide by 2π (i.e. 2pi) to get the expected result."
        ) phase
    end
end
