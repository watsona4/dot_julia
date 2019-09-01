"""

The coherence time of one or more DutyCycles.

$(SIGNATURES)

For a single duty cycle, the returned coherence time is derived from
its period and the uncertainty of the period based on the assumption
that a perfectly repeating dutycycle is compared to an absolutely
certain reference timing.

!!! info "To Do"
    Consider implementing optional keyword arguments for modeling
    phase noise.

!!! info "To Do"
    Implement for more than one DutyCycle.

"""
function coherencetime(d::AbstractDutyCycle)
    T1 = period(d)
    if isinf(T1) || isnan(T1) || iszero(T1)
        return zero(T1)
    end
    u = Unitful.unit(T1)
    val = Measurements.value(T1 / u) * u
    dev = Measurements.uncertainty(T1 / u) * u
    periods = val / dev
    ct = val * periods
    return ct
end

"""

Return true if and only if all arguments (general values, especially
dutycycles) are coherent with each other, i.e. have a rational ratio
to each other and are correlated such that this ratio has
(numerically) zero uncertainty if their type models an
uncertainty. Use the `Measurement` type from packet Measurements (see
[its github
repository](https://github.com/JuliaPhysics/Measurements.jl)) to model
uncertainties.

Technically, a coherence relationship can only be defined between at
least two quantities. However, to generalize as much as possible, zero
or one arguments can be passed and will be treated as coherent if a
given argument has no uncertainty and it is not otherwise disqualified
(by e.g. being zero, infinite, or another NaN value).

"""
function iscoherent(args::Number...; kwargs...)
    N = length(args)
    idx = 0
    for i = 1:N
        if _extractdutycycle(args[i]) !== 1
            idx = i
            break
        end
    end
    if idx == 0
        # with no dutycycles involve, the question boils down to
        # wheter the default_period behaves coherently
        return hascoherence_ratio(default_period(), default_period())
    end
    # we do have at least one dutycycle: periods must be compatible
    units = Unitful.unit(period(_extractdutycycle(args[idx])))
    # use a unit conversion where a possible error message is most
    # informative: transform to units and strip them later, rather
    # than converting the ratio to Unitful.NoUnits
    if length(args) == 1
        # handle a single argument in a specialized manner (to return
        # true for a CoherentDutyCycle, even if its period is
        # uncertain and hence hascoherence_ratio would return false,
        # but only if it is coherent with regard to the
        # default_period())
        return hascoherence_ratio(
            (uconvert(
                units,
                period(_extractdutycycle(
                    args[1],
                    force=true
                ))
            ) / units)::Real,
            default_period();
            kwargs...
        )
    end
    # handle multiple arguments: Interprete them as DutyCycles
    return hascoherence_ratio(
        [(uconvert(
            units,
            period(_extractdutycycle(
                arg,
                force=true
            ))
        ) / units)::Real for arg in args]...;
        kwargs...
    )
end

"""

Return true if there is a rational ratio with (within numerical
precision) zero uncertainty between the periods given as
arguments. Keyword arguments are `tol`, the tolerance for accepting
relative uncertainty for this ratio, and `maxperiods`, the maximum
number of repetitions of either period to consider coherent, even if a
lower uncertainty in their ratio suggests they should be considered
coherent.


"""
function hascoherence_ratio(
    arg1::Number=1, moreargs::Number...;
    tol::Real=0, kwargs...
)
    if isempty(moreargs)
        if arg1 == zero(arg1) || isnan(arg1) || isinf(arg1)
            # for consistency with coherence_ratio, treat zero and
            # infinity (and the like) as incoherent
            return false
        end
        # treat a single argument as coherent only if it has (within
        # the limits of the square root of the machine precision) zero
        # uncertainty (which the default argument fulfills)
        arg1val = arg1 / unit(arg1)
        if tol <= zero(tol)
            val = Measurements.value(arg1val)
            if _isrational(val)
                # use zero tolerance for exact integers and fractions
                tol = zero(tol)
            else
                tol = sqrt(eps(val))
            end
        end
        return abs(Measurements.uncertainty(arg1val)) < tol
    end
    for extraarg in moreargs
        ratio = coherence_ratio(arg1, extraarg; kwargs...)
        if isinf(ratio)
            # no (finite) ratio found
            return false
        end
    end
    return true
end

"""

Calculate the rational ratio `abs(a//b)` (or, if a and b are not both
numerically exact types, a rationalization of `abs(a/b)`) of its
arguments if these behave coherently, i.e. if they are commensurate
and hence their ratio is rational, neither zero or infinity, and has
zero uncertainty, see [`hascoherence_ratio`](@ref) for modeling
uncertainties. Otherwise, return an infinite rational which is one
with zero denominator (and nonzero nominator, a condition enforced by
the implementation of `Rational` in julia). The return type is big
(i.e. `Rational{BigInt}`) if and only if either one of the arguments
is big (e.g. `BigFloat`) or the call is performed with a result type
parameter preprended before the other arguments,
i.e. `coherenceratio(Rational{BigInt}, a, b)`. Beware that when using
small integer types, the result may overflow, as is the usual behavior
of for small integer types in julia.

Keyword arguments can be used to influence the behavior. If
`maxperiods` is positive, then this restricts the maximum number of
repetitions of the main arguments that are allowed for them to be
considered coherent. If `tol` is a positive number, it is used as
tolerance for the rationalization of ratios of arguments if at least
one of them is an inexact type. If it is not given (or nonpositive),
it will be automatically assigned based on the numerical precision of
the types of the arguments. Note that setting tol below
`1.0/maxperiods` will preempt maxperiods from taking effect. If `tol`
is given (and, again, positive) it will also be used to access the
relative uncertainty in the coherence ratio to be returned, allowing a
nonzero uncertainty to still be considered coherent.

To Do: Better than an overflow would be to return an infinite value
(incorrectly indicating incoherenence) in that case, as the extreme of
taking infinity instead of an overflow would be incoherence (but the
limit of taking the overflowing values to infinity could be either
zero or infinity).

"""
function coherence_ratio(
    ratio::Rational{T}; maxperiods::Integer=0
) where {T<:Integer}
    if maxperiods > 0
        incoherent = Rational{T}(one(T), zero(T))
        if abs(denominator(ratio)) > maxperiods
            return incoherent # too many periods of a
        elseif abs(numerator(ratio)) > maxperiods
            return incoherent # too many periods of b
        end
    end
    return ratio
end
# this method removes units and dispatches on big or small types
function coherence_ratio(a::Number, b::Number; kwargs...)
    T = Int
    au = unit(a)
    bu = unit(b)
    av = a / au
    bv = b / bu
    u = unit(a) / unit(b)
    if av isa typeof(big(av))
        T = BigInt
    elseif bv isa typeof(big(bv))
        T = BigInt
    end
    r = coherence_ratio(Rational{T}, av, bv; kwargs...) * u
    @debug begin
        # if debug messages are activated, perform some type assertion
        R = typeof(r)
        if r isa Rational && !(r isa Rational{T})
            @warn "Wanted Rational{T}, got r" T typeof(r)
        end
        "Wanted Rational{T} and got r", T, typeof(r)
    end
    return r
end
coherence_ratio(
    T::Type{<:Rational}, a::Number, b::Number; kwargs...
) = coherence_ratio(T, a/unit(a), b/unit(b), kwargs...) *
    (unit(a)/unit(b))
function coherence_ratio(
    ::Type{Rational{T}}, a::ExactBuiltinReal, b::ExactBuiltinReal;
    maxperiods::Integer=0,
    tol::Real=0
) where {T<:Integer}
    incoherent = Rational{T}(one(T), zero(T))
    # if the values cannot form (non-zero or non-infinite) ratios,
    # treat them as incoherent
    if iszero(a) || isinf(a) || isnan(a)
        return incoherent
    elseif iszero(b) || isinf(b) || isnan(b)
        return incoherent
    end
    # treat zero or infinite ratios as incoherent (i.e. infinite
    # coherence_ratio)
    if denominator(a) == zero(T) || denominator(b) == zero(T)
        return incoherent
    end
    ratio = abs(Rational{T}(a // b))
    # note that Measurements does not support ExactNumber types as
    # backing types, so we do not need to extract an uncertainty that
    # will be reported as exactly zero anyways.
    return coherence_ratio(ratio, maxperiods=maxperiods)
end
function coherence_ratio(
    ::Type{Rational{T}}, a::Real, b::Real;
    maxperiods::Integer=0,
    tol::Real=0
) where {T<:Integer}
    # assert specialized dispatch to method definition above
    @assert !(a isa ExactBuiltinReal && b isa ExactBuiltinReal)
    incoherent = Rational{T}(one(T), zero(T))
    ratio = incoherent
    # if the values cannot form (non-zero or non-infinite) ratios,
    # treat them as incoherent
    if iszero(a) || isinf(a) || isnan(a)
        return incoherent
    elseif iszero(b) || isinf(b) || isnan(b)
        return incoherent
    end
    approxratio = abs(a / ((T isa BigInt) ? big(b) : b))
    if tol <= zero(tol)
        # Use sqrt of machine precision as a decent default.
        tol = sqrt(eps(a/b))
        @assert tol >= zero(tol)
    end
    value_approxratio = Measurements.value(approxratio)
    uncertainty = Measurements.uncertainty(approxratio)
    rel_uncertainty = uncertainty / value_approxratio
    if rel_uncertainty > tol
        # the ratio has significant uncertainty; assume that this
        # means it will end up being irrational or fluctuate
        return incoherent
    end
    # note that "exact" is only true within the tolerance tol
    ratio = rationalize(T, value_approxratio, tol=tol)
    return coherence_ratio(ratio, maxperiods=maxperiods)
end
# allow forming a coherence ratio of the type radians to 2π
coherence_ratio(a::Real, b::Irrational; kwargs...) =
    coherence_ratio(a, convert(typeof(float(a)), b); kwargs...)
