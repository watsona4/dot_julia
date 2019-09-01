"""

The `Base.isapprox` method for type `DutyCycle`, also accessible in
julia as the operator `≈`. Extra keyword arguments are assumed to
relate to the values whilst for phases a sensible default (the square
root of the machine precision for a value of 1) is always used. Note
that this implies ignoring (ultra)short spikes even if their
time-integral is significant. The periods of the DutyCycles must match
(within the default tolerance): False is returned even if one
DutyCycle is simply a repetition of the other.

!!! note "Outdated Note: Disregard"
    A comparison with a regular number (or Unitful.Quantity) will
    succeed even if only the [`autoavg`](@ref) of the values
    agrees. If this behavior is undesired, the keyword argument
    `matchaverage=false` must be given. The existing `Base.isapprox`
    method and the derived operators `≈` and `` are amended
    accordingly to allow passing this new option even for comparisons
    where no DutyCycle objects are involved.

!!! info "To Do"
    Update the above documentation which is outdated:
    `matchaverage=false` is the default now and it would make sense
    to completely remove this option.

"""
Base.isapprox(
    a::DutyCycle{T1,U1,V1},
    b::DutyCycle{T2,U2,V2};
    matchaverage = false,
    kwargs...
) where {T1,U1,V1,T2,U2,V2} =
    compare((x,y) -> isapprox(x,y; kwargs...), a, b)
Base.isapprox(
    a::AbstractDutyCycle, b::NoDimNum; matchaverage = false, kwargs...
) = matchaverage && isapprox(autoavg(a), b; kwargs...)
Base.isapprox(
    a::NoDimNum, b::AbstractDutyCycle; matchaverage = false, kwargs...
) = matchaverage && isapprox(a, autoavg(b); kwargs...)
Base.isapprox(
    a::Unitful.Quantity{<:AbstractDutyCycle,D,U},
    b::Unitful.Quantity{T,D,U2};
    matchaverage = false,
    kwargs...
) where {T,D,U,U2} =
    matchaverage && isapprox(autoavg(a), b; kwargs...)
Base.isapprox(
    a::Unitful.Quantity{T,D,U2},
    b::Unitful.Quantity{<:AbstractDutyCycle,D,U};
    matchaverage = false,
    kwargs...
) where {T,D,U,U2} =
    matchaverage && isapprox(a, autoavg(b); kwargs...)
function Base.isapprox(
    a::Unitful.Quantity{<:AbstractDutyCycle,D1,U1},
    b::Unitful.Quantity{<:AbstractDutyCycle,D2,U2};
    matchaverage = false,
    atol=zero(1unit(a)),
    kwargs...
) where {D1, D2, U1, U2}
    if D1 != D2
        # dimensions do not match: a and b are incomparable
        return false
    end
    units = unit(a)
    return isapprox(
        a / units,
        uconvert(units, b) / units;
        matchaverage = matchaverage,
        atol = uconvert(units, atol) / units,
        kwargs...
    )
end

"""

Equality operator. Should return true only if the all values and
phases of the DutyCycle object being compared match precisely, without
allowing for numerical inaccuracies (but allowing for different
internal representations). In normal usage, one prefers
[`isapprox`](@ref).

Note: The current implementation contains the bug that phases only
need to match approximately.

"""
Base.:(==)(
    a::DutyCycle{T1,U1,V1}, b::DutyCycle{T2,U2,V2}
) where {T1,U1,V1,T2,U2,V2} =
    compare((x,y) -> x == y, a, b)

# compare a and b instant-wise by calling method(aval, bval),
# short-circuiting to return false as soon as it returns false for the
# first time
function compare(
    method::Function,
    a::CoherentDutyCycle{T1,U1,V1}, b::CoherentDutyCycle{T2,U2,V2};
    matchaverage = false, kwargs...
) where {T1,U1,V1,T2,U2,V2}
    if unit(T1) != unit(T2)
        return false
    end
    U = promote_type(U1, U2)
    # absolute tolerance for phase comparisons
    Utol = zero(U)
    if !_isrational(U)
        Utol = sqrt(eps(one(U)))
    end
    # the absolute tolerance for U, Utol, is the correct relative
    # rolerance for T, keyword parameter rtol to isapprox
    if !(isapprox(a.period, b.period, rtol=Utol))
        return false
    end
    aphases = fractionaldurations(a)
    bphases = fractionaldurations(b)
    phase = zero(U) # phase at which next comparison begins
    ai = 1
    phasea = zero(U) # phase at which a.phases[ai] begins
    bi = 1
    phaseb = zero(U) # phase at which b.phases[bi] begins
    while phase < one(U) - Utol
        @debug "Phase matching loop for value comparison" phase phasea phaseb ai bi
        # calculate remaining phases rema, remb of the current,
        # respective index into their phases vector (ai or bi)
        rema = aphases[ai] - (phase - phasea)
        @assert rema >= -Utol #zero(U)
        remb = bphases[bi] - (phase - phaseb)
        @assert remb >= -Utol #zero(U)
        if rema > Utol && remb > Utol
            # use keyword arguments kwargs... for value comparison
            # only (rather than for phase comparisons as well)
            if !method(a.values[ai], b.values[bi])
                @debug "Aborting comparison: inequality found" phase phasea phaseb ai bi
                return false
            end
        end
        if rema < remb
            phase += rema
            phasea += aphases[ai]
            ai += 1
        else
            phase += remb
            phaseb += bphases[bi]
            bi += 1
        end
    end
    return true
end
# comparisons between coherent and incoherent duty cycles should fail
compare(
    method::Function,
    a::IncoherentDutyCycle, b::CoherentDutyCycle;
    matchaverage = false, kwargs...
) = false
compare(
    method::Function,
    a::CoherentDutyCycle, b::IncoherentDutyCycle;
    matchaverage = false, kwargs...
) = false
# compare two incoherent duty cycles: only total times can be checked
function compare(
    method::Function,
    a::IncoherentDutyCycle{T1,U1,V1}, b::IncoherentDutyCycle{T2,U2,V2};
    matchaverage = false, kwargs...
) where {T1,U1,V1,T2,U2,V2}
    if unit(T1) != unit(T2)
        return false
    end
    U = promote_type(U1, U2)
    # absolute tolerance for phase comparisons
    Utol = zero(U)
    if !_isrational(U)
        Utol = sqrt(eps(one(U)))
    end
    # the absolute tolerance for U, Utol, is the correct relative
    # rolerance for T, keyword parameter rtol to isapprox
    if !(isapprox(a.period, b.period, rtol=Utol))
        # this result would be strange, as both should be positive
        # infinity; To Do: Can we do away with it then? Or is it
        # better to keep it in case we want to extend what values we
        # allow for incoherent periods (other NaNs, perhaps?)
        return false
    end
    # To Do: Consider sorting values in IncoherentDutyCycles by
    #        default so we don't have to do that here for every
    #        comparison
    avalues = values(a)
    bvalues = values(b)
    aidx = sortperm(avalues)
    bidx = sortperm(bvalues)
    at = fractionaltimes(a)
    bt = fractionaltimes(b)
    # now avalues[aidx[i]] is sorted, and so is bvalues[bidx[j]]
    aN = length(avalues)
    bN = length(bvalues)
    ai = 1
    bi = 1
    arem = at[aidx[ai]] # remaining fractional time for index ai
    @assert arem >= zero(U)
    brem = bt[bidx[bi]] # likewise
    @assert brem >= zero(U)
    while (ai <= aN) && (bi <= bN)
        if method(avalues[aidx[ai]], bvalues[bidx[bi]])
            return false
        end
        # Note: If the following throws an index-out-of-bounds
        #       exception, this must be due to a fractional-times
        #       anormalization (or due to roundoff errors which we may
        #       have to handle...)
        if arem < brem
            brem -= arem
            ai += 1
            arem = at[idx[ai]]
        else
            arem -= brem
            brem = 0
            brem = bt[idx[bi]]
        end
    end
    # assert that the comparison is properly finished (and that the
    # fractional times were properly normalized within Utol)
    @assert ai == aN && bi == bN
    @assert isapprox(arem, 0, atol=Utol)
    @assert isapprox(brem, 0, atol=Utol)
    return true
end
