module CorrNoise

using Random

export Flat128RNG, initflatrng128, GaussRNG, Oof2RNG, OofRNG, randoof2, randoof

const scalefactor = 1 / (1 + 0xFFFFFFFF)

function twiddle(var::UInt32)
    for i = 1:9
        var = xor(var, var << 13)
        var = xor(var, var >> 17)
        var = xor(var, var << 5)
    end
    
    var
end

"""
    Flat128RNG

State of the base-128 uniform random generator. Initialize this using the
function `initflatrng128`.
"""
mutable struct Flat128RNG <: AbstractRNG
    state::Array{UInt32}
end

function nextstate(state::Array{UInt32})
    tmp::UInt32 = xor(state[1], state[1] << 11)
    state[1] = state[2]
    state[2] = state[3]
    state[3] = state[4]
    state[4] = xor(xor(state[4], state[4] >> 19), xor(tmp, tmp >> 8))
    
    state
end

"""
    initflatrng128(xstart = 123456789, ystart = 362436069, zstart = 521288629, wstart = 88675123)

Initialize a flat random number generator with period 2^128. To draw random numbers,
use the `Base.rand` function as usual.

Example:
```
rng = initflatrng128()
print([rand(rng) for i in 1:4])
```
"""
function initflatrng128(xstart = 123456789, ystart = 362436069, zstart = 521288629, wstart = 88675123)
    rng = Flat128RNG(Array{UInt32}([xstart, ystart, zstart, wstart]))
    
    # Suffle the bits in the seeds
    for i = 1:4
        rng.state[i] = twiddle(rng.state[i])
    end
    
    # Burnin the RNG
    for i = 1:17
        rng.state = nextstate(rng.state)
    end
    
    rng
end

function Base.rand(rng::Flat128RNG)
    result = rng.state[4] * scalefactor
    nextstate(rng.state)
    result
end

# Gaussian distribution

mutable struct GaussRNG
    flatrng
    empty::Bool
    gset
end

"""
    GaussRNG(flatrng::AbstractRNG)
    GaussRNG(seed=0)

Initialize a Gaussian RNG. The parameter `flatrng` must be a uniform RNG.
If a `seed` is used, then a `MersenneTwister` RNG is used.
"""
GaussRNG(flatrng::AbstractRNG) = GaussRNG(flatrng, true, 0)
GaussRNG(seed=0) = GaussRNG(MersenneTwister(seed))

function Base.randn(state::GaussRNG)
    if state.empty
        local v1, v2, rsq
        
        while true
            v1 = 2 * rand(state.flatrng) - 1.0
            v2 = 2 * rand(state.flatrng) - 1.0
            rsq = v1^2 + v2^2
            if 0 < rsq < 1
                break
            end
        end
        
        fac = sqrt(-2log(rsq) / rsq)
        state.gset = v1 * fac
        state.empty = false
        
        v2 * fac
    else
        state.empty = true
        state.gset
    end
end

# 1/f^2 distribution

mutable struct Oof2RNG
    normrng
    c0::Float64
    c1::Float64
    d0::Float64
    x1::Float64
    y1::Float64
end

"""
    Oof2RNG(normrng, fmin, fknee, fsample)

Create a `Oof2RNG` RNG object. It requires a gaussian RNG generator in `normrng` (use `GaussRNG`),
the minimum frequency (longest period) in `fmin`, the knee frequency and the sampling frequency.
The measure unit of the three frequencies must be the same (e.g., Hz).

Use `randoof2` to draw samples from a `Oof2RNG` object, as in the following example:
```
rng = Oof2RNG(GaussRNG(), 1e-3, 1.0, 1e2)
print([randoof2(rng) for i in 1:4])
```
"""
function Oof2RNG(normrng, fmin::Number, fknee::Number, fsample::Number)
    w0 = π * fmin / fsample
    w1 = π * fknee / fsample
    
    Oof2RNG(normrng,
            (1.0 + w1) / (1.0 + w0),
            (w1 - 1.0) / (1.0 + w0),
            (1.0 - w0) / (1.0 + w0),
            0,
            0)
end

function oof2filter(rng::Oof2RNG, x2::Float64)
    y2 = rng.c0 * x2 + rng.c1 * rng.x1 + rng.d0 * rng.y1
    rng.x1 = x2
    rng.y1 = y2
    
    y2
end

"""
    randoof2(rng::Oof2RNG)

Draw a random sample from a 1/f^2 distribution.
"""
randoof2(rng::Oof2RNG) = oof2filter(rng, randn(rng.normrng))


# 1/f^alpha distribution

mutable struct OofRNG
    normrng
    slope
    fmin
    fknee
    fsample
    oof2states::Array{Oof2RNG}
end

wminmax(fmin::Number, fknee::Number) = (log10(2 * π * fmin), log10(2 * π * fknee))

function numofpoles(fmin::Number, fknee::Number, fsample::Number)
    (wmin, wmax) = wminmax(fmin, fknee)
    
    convert(Int32, floor(2(wmax - wmin) + log10(fsample)))
end

const OOF2STATESIZE = 5
oofstatesize(fmin::Number, fknee::Number, fsample::Number) = OOF2STATESIZE * numofpoles(fmin, fknee, fsample)

"""
    OofRNG(normrng, slope, fmin, fknee, fsample)

Create a `OofRNG` RNG object. It requires a gaussian RNG generator in `normrng`
(use `GaussRNG`), the slope α of the noise in `slope`, the minimum frequency
(longest period) in `fmin`, the knee frequency and the sampling frequency. The
measure unit of the three frequencies must be the same (e.g., Hz).

Use `randoof` to draw samples from a `OofRNG` object, as in the following example:
```
rng = OofRNG(GaussRNG(), -1.5, 1e-3, 1.0, 1e2)
print([randoof(rng) for i in 1:4])
```
"""
function OofRNG(normrng, slope::Number, fmin::Number, fknee::Number, fsample::Number)
    (wmin, wmax) = wminmax(fmin, fknee)
    a = -slope
    nproc = numofpoles(fmin, fknee, fsample)
    dp = (wmax - wmin) / nproc
    
    p = wmin + (1 - a / 2) * dp / 2
    z = p + a * dp / 2
    
    oof2states = Array{Oof2RNG}(undef, nproc)
    for i = 1:nproc
        oof2states[i] = Oof2RNG(normrng, 10^p / (2π), 10^z / (2π), fsample)
        
        p += dp
        z = p + a * dp / 2
    end
    
    OofRNG(normrng, slope, fmin, fknee, fsample, oof2states)
end

"""
    randoof(rng::OofRNG)

Draw a random sample from a 1/f^α distribution.
"""
function randoof(rng::OofRNG)
    x2 = randn(rng.normrng)
    for curstate in rng.oof2states
        x2 = oof2filter(curstate, x2)
    end
    
    x2
end

end # module
