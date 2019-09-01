"""

Return a function that describes the waveform of a coherent or (with a
caveat, see below) an incoherent DutyCycle as a function of fractional
duration, optionally stripping units if the optional keyword argument
`stripunits` is set to true.

The argument to this function, time, should share the dimensions of
ther `period` of the dutycycle but can alternatively be dimensionless
to indicate a phase (which only works if the period is not
dimensionless as well). `Unitful` quantities can be used to specify
units, including angular units for the phase.

!!! warning "The default phase unit for `waveform` is Radians!"
    Elsewhere, including the function `phaseshift`, phases are
    by default in units of cycles. This one differs.

!!! info "To Do"
    Change the default elsewhere and point out that by passing
    values derived from UnitfulAngles.turn (or perhaps a
    DutyCycles.cycles unit to be made equivalent to it),
    exact fractions of a cycle can be specified.

This method also accepts incoherent waveforms, but scrambles their
phase, returning a (properly weighted) random choice from the values
it assumes.

!!! info "To Do"
    If/when upgrading IncoherentDutyCycles to support information
    about the shortest spikes that can occur, upgrade this behavior
    to reflect this minimum dwell time at a given value.

"""
function waveform(n::Number; stripunits=false)
    d = _extractdutycycle(n)
    c = _extractnondutycycle(n)
    if stripunits && c isa Unitful.Units
        return x -> valueat(d, x)
    elseif Unitful.dimension(c) == Unitful.NoDims
        c2 = uconvert(Unitful.NoUnits, c)
        return x -> c2 * valueat(d, x)
    end
    return x -> c * valueat(d, x)
end

"""

Return the value assumed by a DutyCycle at an instant in time or a
given phase. If the `Unitful` dimension of the second argument are
ambigious between the two, default to a phase.

"""
function valueat(d::AbstractDutyCycle, instant::Number)
    if Unitful.dimension(instant) == Unitful.dimension(period(d))
        # first try interpreting instant as a temporal instant
        return _valueatfractionaltime(
            d,
            Unitful.uconvert(
                Unitful.NoUnits, instant / period(d)
            )
        )
    elseif Unitful.dimension(instant) == Unitful.NoDims
        # otherwise, interpret instant as a phase in radians
        return _valueatfractionaltime(
            d,
            Unitful.uconvert(
                UnitfulAngles.turn, instant
            ) / UnitfulAngles.turn
        )
    end
    throw(DomainError(string(
        "second argument must share the dimensions of the period ",
        "of the first argument, or be dimensionless"
    )))
end
valueat(x::Number, instant::Number) = _extractnondutycycle(x) *
    valueat(_extractdutycycle(x), instant)
function _valueatfractionaltime(
    d::AbstractCoherentDutyCycle,
    instant::Real
)
    instant = mod(instant, one(instant))
    if instant < zero(instant)
        # handle the case of a negative sign
        instant += one(instant)
    elseif instant >= one(instant)
        # handle rounding error (should only reach equality and never
        # be larger than that, but this handler would be fit for an
        # is-larger relationship as well, if the Base or some
        # @fastmath behavior should change)
        instant -= one(instant)
    end
    fts = fractionaltimes(d)
    idx = 1
    ft = instant
    while idx < length(fts) && ft > fts[idx]
        ft -= fts[idx]
        idx += 1
    end
    return values(d)[idx]
end
function _valueatfractionaltime(
    d::AbstractIncoherentDutyCycle,
    instant::Real
)
    instant = rand() # a random number in the interval [0,1)
    fts = fractionaltimes(d)
    idx = 1
    while idx < length(fts) && instant > fts[idx]
        instant -= fts[idx]
        idx += 1
    end
    return values(d)[idx]
end

"""

The (amplitude) spectrum of a DutyCycle or number.

$(SIGNATURES)

This returns the spectrum as a function of the ordinary frequency
``\\nu`` (or `\nu`).  This is the unitary Fourier transform for
ordinary frequencies with appropriate `Unitful` units:

```math
\\mathrm{spectrum}\\big( f(t) \\big)(\\nu)
=
\\int_{-\\infty}^{+\\infty}
f(t)
\\,
e^{-2 \\pi i t \\nu}
\\,
\\mathrm{d}t
```

!!! info "To do"
    Consider also implementing this for a function (waveform).

"""
function spectrum(d::AbstractDutyCycle) end
function spectrum(n::Number; kwargs...)
    c = _extractnondutycycle(n) # units, dimensions
    d = _extractdutycycle(n)
    s = spectrum(d; kwargs...)
    return ν -> c * s(ν) # Greek letter ν (nu), not Latin v
end
function spectrum(
    d::AbstractCoherentDutyCycle{T,U,V};
    harmonics = nothing,
    resolution = nothing
) where {T,U,V}
    # values ys[i]
    ys = values(d)
    ds = durations(d)
    # times ts[i]
    ts = Vector{typeof(
        Measurements.value(ds[1] / Unitful.unit(ds[1])) *
        Unitful.unit(ds[1])
    )}(
        undef,
        length(ds) + 1
    )
    ts[1] = zero(ts[1])
    for i = 1:length(ds)
        ts[i+1] = ts[i] + Measurements.value(
            ds[i] / Unitful.unit(ds[i])
       ) * Unitful.unit(ds[i])
    end
    # note a Geek nu (ν, Latex \nu) is used throughout, not a Latin v
    f0m = fundamental_frequency(d)
    f0 = Measurements.value(f0m / Unitful.unit(f0m)) *
        Unitful.unit(f0m)
    # estimate number of harmonics, if not specified
    if harmonics === nothing
        # To Do: make an estimate based on smallest width, etc.
        # mind = minimum(ds)
        # minv, maxv = extremavals(d)
        # maxstep = maxv - minv
        # # now maxstep and mind is an estimate of the maximum step
        # # size and minimum duration; the combination should not
        # # underestimate the highest harmonic content...
        harmonics = 10_000
    end
    # spectrum (complex Fourier series coefficients) ss[k] at harmonic
    # frequencies ν = k * f0, plus s0
    s0 = complex(mean(d))
    ss = Vector{typeof(s0)}([zero(s0) for k = 1:harmonics])
    for i = 1:length(ds)
        for k = 1:harmonics
            # even ("cosine") Fourier coefficient for the pulse
            # centered around t = 0
            Ak = 2 * ys[i] / (k * π) *
                sin(k * π * f0 * (ts[i+1] - ts[i]))
            # shifted pulse
            ss[k] += exp(-π * im * (ts[i] + ts[i+1]) * k * f0) * Ak
        end
    end
    # this should model the effect of jitter in the period
    # (or of an evaluation window)
    #
    # note that this is used to "transform" the Dirac delta function
    # omitted from (but implied in) ss[k] back to a normal number,
    # which influences the choice of units
    if resolution === nothing
        ct = coherencetime(d)
        if iszero(ct)
            resolution = f0 # To Do: reconsider if this is sensible
        elseif isinf(ct)
            resolution = f0 / harmonics
        else
            resolution = inv(ct)
        end
    end
    local fres::typeof(f0)
    if Unitful.dimension(resolution) == Unitful.dimension(f0)
        fres = resolution
    elseif (
        Unitful.dimension(resolution) == Unitful.dimension(period(d))
    )
        # try interpreting the resolution as a time, not a frequency
        fres = inv(resolution)
    else
        throw(DomainError(
            "resolution has dimensions of neither period nor frequency"
        ))
    end
    if fres <= zero(fres)
        throw(DomainError("resolution must be positive"))
    end
    # the normal distribution, centered around zero frequency,
    # integral one, full width fres
    #
    # note that a Greek ν (nu) is used, not a Latin v
    return function(ν::Number)
        if Unitful.dimension(ν) != Unitful.dimension(f0)
            throw(DomainError("frequency has wrong dimensions"))
        end
        res(Δν) =
            exp(-0.5 * (Δν / fres)^2) / (sqrt(2*π) * fres)
        s_sum = s0 * res(ν)
        for k = 1:length(ss)
            # convolute (fold) with res(ν) which is equivalent to
            # multiplying (i.e. filtering) the input signal with it            
            s_sum += ss[k] * res(ν - k * f0)
        end
        return s_sum
    end
end

"""

The power spectral density of a DutyCycle (or a number promoted to a
DutyCycle).

$(SIGNATURES)

See [`spectrum`](@ref) for the optional keyword arguments.

"""
function psd(n::Number; kwargs...)
    if n isa Unitful.Power
        # n is a power
        return spectrum(n; kwargs...)
    end
    # n is an amplitude so needs to be squared
    powerspectrum = spectrum(n^2; kwargs...)
    # note that a Greek ν (nu) is used, not a Latin v
    return ν -> sqrt(abs(powerspectrum(ν)))
end
