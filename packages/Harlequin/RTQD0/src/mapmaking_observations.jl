
################################################################################
# Observations

@doc raw"""
    mutable struct Observation{T <: Real}

An *observation* is a sequence of time-ordered data (TOD) that has
been acquired by some detector. It implements the following fields:

- `time`: an array of `N` elements, representing the time of the
  sample. Being defined as an `AbstractArray`, a range (e.g.,
  `0.0:0.1:3600.0`) can be used to save memory
- `pixidx`: an array of `N` elements, each being a pixel index in a
  map. In no way the Healpix pixelization scheme is enforced; in fact,
  the map must not even be spherical.
- `psi_angle`: an array of `N` elements, each containing the
  orientation of the polarization angle with respect to some fixed
  reference system (e.g., the Ecliptic plane). The angles must be in
  **radians**.
- `tod`: an array of `N` elements, containing the actual data measured
  by the instrument and already calibrated to some physical units
  (e.g., K_CMB)
- `sigma_squared`: an array of `N` elements, containing the squared
  RMS of each sample. To save memory, you should usually use a
  `RunLengthArray` here.
- `flagged`: a Boolean array of `N` elements, telling whether the
  sample should be discarded (`true`) or not (`false`) during the
  map-making process.
- `name`: a string representing the detector. This is used only for
  debugging purposes.

To create an observation, the constructor takes *keyword arguments*
instead of parameters; in this way, the code should be more
readable. Also, sensible defaults will be provided for the missing
fields:

```julia
# We do not specify "sigma_squared" nor "flagged", so they will be
# initialized to a vector of ones and a vector of `false`
obs = Observation{Float64}(
    time = 0.0:0.1:3600.0,
    pixidx = 1:3601,
    psi_angle = zeros(3601),
    tod = randn(3601),
)
```

"""
mutable struct Observation{T <: Real}
    time::AbstractVector{T}
    pixidx::Vector{Int}
    psi_angle::Vector{T}

    tod::Vector{T}
    sigma_squared::AbstractVector{T}
    flagged::AbstractVector{Bool}

    name::String
    
    function Observation{T}(
        ;
        time = T[],
        pixidx = Int[],
        psi_angle = T[],
        tod = T[],
        sigma_squared = T[],
        flagged = Bool[],
        name = "unnamed",
    ) where {T <: Real}
        @assert !isempty(pixidx)

        nsamples = length(pixidx)
        
        int_time = isempty(time) ? (0:(nsamples - 1)) : time
        int_tod = isempty(tod) ? zeros(T, nsamples) : tod
        int_psi_angle = isempty(psi_angle) ? zeros(T, nsamples) : psi_angle
        int_sigma_squared = isempty(sigma_squared) ? RunLengthArray{Int,T}(nsamples, 1.0) : sigma_squared
        int_flagged = isempty(flagged) ? zeros(Bool, nsamples) : flagged

        @assert length(int_time) == nsamples
        @assert length(int_psi_angle) == nsamples
        @assert length(int_tod) == nsamples
        @assert length(int_sigma_squared) == nsamples
        @assert length(int_flagged) == nsamples

        new(
            int_time,
            pixidx,
            int_psi_angle,
            int_tod,
            int_sigma_squared,
            int_flagged,
            name,
        )
    end
end

function Base.show(io::IO, obs::Observation)
    print(io, "Observation(name => \"$(obs.name)\", samples = $(length(obs.time)))")
end

function Base.show(io::IO, ::MIME"text/plain", obs::Observation)

    isempty(obs.time) && println(io, "Observation for detector %(obs.name): empty")
    
    println(
        io,
        @sprintf(
            """Observation for detector %s:
Number of samples....................... %d
Start time.............................. %f
Duration................................ %f
Number of flagged samples............... %d (%.1f%%)
Average level of the TOD................ %e
Average noise^2 level................... %e
""",
            obs.name,
            length(obs.time),
            obs.time[1],
            obs.time[end] - obs.time[1],
            length(obs.flagged[obs.flagged]),
            100 * length(obs.flagged[obs.flagged]) / length(obs.flagged),
            mean(obs.tod),
            mean(obs.sigma_squared),
        )
    )
end
