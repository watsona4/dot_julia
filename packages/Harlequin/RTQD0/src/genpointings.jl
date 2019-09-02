import Printf
import JSON
import Healpix
import LinearAlgebra: dot, ×
import Base: show

using RecipesBase

export MINUTES_PER_DAY,
       DAYS_PER_YEAR,
       rpm2angfreq,
       angfreq2rpm,
       period2rpm,
       rpm2period,
       ScanningStrategy,
       update_scanning_strategy,
       load_scanning_strategy,
       to_dict,
       save,
       time2pointing,
       time2pointing!,
       genpointings,
       genpointings!,
       CORE_SCANNING_STRATEGY,
       PICO_SCANNING_STRATEGY,
       SegmentedTimeSpan

################################################################################

rpm2angfreq(rpm) = 2π * rpm / 60
angfreq2rpm(ω) = ω / 2π * 60

@doc raw"""
    rpm2angfreq(rpm)
    angfreq2rpm(ω)

Convert rotations per minute into angular frequency 2πν (in Hertz), and vice
versa.
"""
rpm2angfreq, angfreq2rpm

period2rpm(p) = 60 / p
rpm2period(rpm) = 60 / rpm

@doc raw"""
    period2rpm(p)
    rpm2perriod(rpm)

Convert a period (time span) in seconds into a number of rotations per minute,
and vice versa.
"""
period2rpm, rpm2period

################################################################################

const MINUTES_PER_DAY = 60 * 24
const DAYS_PER_YEAR = 365.25

@doc raw"""
The structure `ScanningStrategy` encodes the information needed to build a
set of pointing directions. It contains the following fields:

- `omega_spin_hz`: angular speed of the rotation around the spin axis (equal to 2πν)
- `omega_prec_hz`: angular speed of the rotation around the precession axis (equal to 2πν)
- `omega_year_hz`: angular speed of the rotation around the Elliptic axis (equal to 2πν)
- `omega_hwp_hz`: angular speed of the rotation of the half-wave plate (equal to 2πν)
- `spinsunang_rad`: angle between the spin axis and the Sun-Earth direction
- `borespinang_rad`: angle between the boresight direction and the spin axis
- `q1`, `q3`: quaternions used to generate the pointings

Each field has its measure unit appended to the name. For instance, field
`spinsunang_rad` must be expressed in radians.

"""
struct ScanningStrategy
    omega_spin_hz::Float64
    omega_prec_hz::Float64
    omega_year_hz::Float64
    omega_hwp_hz::Float64
    spinsunang_rad::Float64
    borespinang_rad::Float64
    # First quaternion used in the rotation
    q1::Quaternion
    # Third quaternion used in the rotation
    q3::Quaternion
    
    ScanningStrategy(; spin_rpm = 0,
        prec_rpm = 0,
        yearly_rpm = 1  / (MINUTES_PER_DAY * DAYS_PER_YEAR),
        hwp_rpm = 0,
        spinsunang_rad = deg2rad(45.0),
        borespinang_rad = deg2rad(50.0),
    ) = new(rpm2angfreq(spin_rpm),
        rpm2angfreq(prec_rpm),
        rpm2angfreq(yearly_rpm),
        rpm2angfreq(hwp_rpm),
        spinsunang_rad,
        borespinang_rad,
        compute_q1(borespinang_rad),
        compute_q3(spinsunang_rad))

    ScanningStrategy(io::IO) = load_scanning_strategy(io)
    ScanningStrategy(filename::AbstractString) = load_scanning_strategy(filename)
end

compute_q1(borespinang_rad) = qrotation_y(borespinang_rad)
compute_q3(spinsunang_rad) = qrotation_y(π / 2 - spinsunang_rad)

@doc raw"""
    update_scanning_strategy(sstr::ScanningStrategy)

Update the internal fields of a `ScanningStrategy` object. If you change any of the
fields in a `ScanningStrategy` object after it has been created using the constructors,
call this function
before using one of the functions `time2pointing`, `time2pointing!`, `genpointings`,
and `genpointings!`, as they rely on a number of internal parameters that need to be
updated.

```julia
sstr = ScanningStrategy()
# ... use sstr ...

sstr.borespinang_rad *= 0.5
update_scanning_strategy(sstr)
```

"""
function update_scanning_strategy(sstr::ScanningStrategy)
    sstr.q1 = compute_q1(sstr.borespinang_rad)
    sstr.q3 = compute_q3(sstr.spinsunang_rad)
end

################################################################################

# «Exploring cosmic origins with CORE: Survey requirements and mission
# design», Delabrouille et al. (2018), Sect. 5.3
# https://doi.org/10.1088/1475-7516/2018/04/014

@doc raw"""
    CORE_SCANNING_STRATEGY::ScanningStrategy

A [`ScanningStrategy`](@ref) object describing the proposed scanning
strategy of the CORE spacecraft ([Delabrouille et al.,
2018](https://doi.org/10.1088/1475-7516/2018/04/014)).

"""
const CORE_SCANNING_STRATEGY = ScanningStrategy(
    spin_rpm = 1 / 2,
    prec_rpm = 1 / (4 * 24 * 60),      # Precession period is 4 days
    spinsunang_rad = deg2rad(30),
    borespinang_rad = deg2rad(65),
)

# «PICO: Probe of Inflation and Cosmic Origins», Hanany et al. (2019), Sect. 4.1.2
# https://ui.adsabs.harvard.edu/abs/2019arXiv190210541H/abstract

@doc raw"""
    PICO_SCANNING_STRATEGY::ScanningStrategy

A [`ScanningStrategy`](@ref) object describing the proposed scanning
strategy of the PICO spacecraft ([Hanany et al.,
2019](https://ui.adsabs.harvard.edu/abs/2019arXiv190210541H/abstract)).

"""
const PICO_SCANNING_STRATEGY = ScanningStrategy(
    spin_rpm = 1,
    prec_rpm = 1 / (10 * 60),      # Precession period is 10 hr
    spinsunang_rad = deg2rad(26),
    borespinang_rad = deg2rad(69),
)

################################################################################

function load_scanning_strategy(io::IO)
    data = JSON.Parser.parse(io)

    sstr_data = data["scanning_strategy"]

    ScanningStrategy(spin_rpm = sstr_data["spin_rpm"],
        prec_rpm = sstr_data["prec_rpm"],
        yearly_rpm = sstr_data["yearly_rpm"],
        hwp_rpm = sstr_data["hwp_rpm"],
        spinsunang_rad = sstr_data["spinsunang_rad"],
        borespinang_rad = sstr_data["borespinang_rad"])
end

function load_scanning_strategy(filename::AbstractString)
    open(filename) do inpf
        load_scanning_strategy(inpf)
    end
end

@doc raw"""
    load_scanning_strategy(io::IO) -> ScanningStrategy
    load_scanning_strategy(filename::AbstractString) -> ScanningStrategy

Create a `ScanningStrategy` object from the definition found in the JSON file
`io`, or from the JSON file with path `filename`. See also
[`load_scanning_strategy`](@ref).

"""
load_scanning_strategy

################################################################################

@doc raw"""
    to_dict(sstr::ScanningStrategy) -> Dict{String, Any}

Convert a scanning strategy into a dictionary suitable to be serialized using
JSON or any other structured format. See also [`save`](@ref).

"""
function to_dict(sstr::ScanningStrategy)
    Dict("scanning_strategy" => Dict("spin_rpm" => angfreq2rpm(sstr.omega_spin_hz),
        "prec_rpm" => angfreq2rpm(sstr.omega_prec_hz),
        "yearly_rpm" => angfreq2rpm(sstr.omega_year_hz),
        "hwp_rpm" => angfreq2rpm(sstr.omega_hwp_hz),
        "spinsunang_rad" => sstr.spinsunang_rad,
        "borespinang_rad" => sstr.borespinang_rad))
end

function save(io::IO, sstr::ScanningStrategy)
    print(io, JSON.json(to_dict(sstr), 4))
end

function save(filename::AbstractString, sstr::ScanningStrategy)
    open(filename, "w") do outf
        save(outf, sstr)
    end
end

@doc raw"""
    save(io::IO, sstr::ScanningStrategy)
    save(filename::AbstractString, sstr::ScanningStrategy)

Write a definition of the scanning strategy in a self-contained JSON file.
You can reload this definition using one of the constructors of
[`ScanningStrategy`](@ref).

"""
save

################################################################################

function show(io::IO, sstr::ScanningStrategy)
    Printf.@printf(io, """Scanning strategy:
    Spin angular velocity........................................ %g rot/s
    Precession angular velocity.................................. %g rot/s
    Yearly angular velocity around the Sun....................... %g rot/s
    Half-wave plate angular velocity............................. %g rot/s
    Angle between the spin axis and the Sun-Earth direction (α).. %f°
    Angle between the boresight direction and the spin axis (β).. %f°
""",
        sstr.omega_spin_hz,
        sstr.omega_prec_hz,
        sstr.omega_year_hz,
        sstr.omega_hwp_hz,
        rad2deg(sstr.spinsunang_rad),
        rad2deg(sstr.borespinang_rad))
end

function drawline(x1, y1, x2, y2; closepath = true)
    points = []
    append!(points, [(x1, y1), (x2, y2)])

    closepath && push!(points, (missing, missing))

    points
end

function drawarrow(x1, y1, x2, y2, head_length)
    points = []
    append!(points, [(x1, y1), (x2, y2)])

    head_aperture = π / 6
    angle = atan(y2 - y1, x2 - x1)
    sin1, cos1 = sincos(angle + π - head_aperture)
    sin2, cos2 = sincos(angle + π + head_aperture)
    append!(points, [(x2 + head_length * cos1, y2 + head_length * sin1),
                     (x2, y2),
                     (x2 + head_length * cos2, y2 + head_length * sin2)])
    
    push!(points, (missing, missing))

    points
end

function drawarc(center_x, center_y, radius, angle1, angle2; closepath = true)
    points = []
    append!(points, [(center_x + radius * cos(θ), center_y + radius * sin(θ))
                     for θ in range(angle1, angle2;
                                    length=round(Int, abs(angle2 - angle1) / 0.05))])

    closepath && push!(points, (missing, missing))

    points
end

function drawdoublearc(center_x, center_y, radius1, radius2, angle1, angle2)
    points = []

    append!(points, drawarc(center_x, center_y, radius1, angle1, angle2))
    append!(points, drawarc(center_x, center_y, radius2, angle1, angle2))

    points
end

function drawrotatedellipse(center_x, center_y, radius_x, radius_y, tilt_angle;
                            n = 40, closepath = true)

    sintilt, costilt = sincos(tilt_angle)
    rotmatr = [costilt -sintilt; sintilt costilt]

    points = []
    append!(points, [Float64[center_x, center_y] + rotmatr * Float64[radius_x * cos(θ), radius_y * sin(θ)]
                     for θ in range(0, 2π, length=n)])

    closepath && push!(points, (missing, missing))

    points
end

@recipe function plot_sstr(sstr::ScanningStrategy)
    α = sstr.spinsunang_rad
    β = sstr.borespinang_rad

    paths = []
    label_array = []

    arrow_head_size = 0.05

    #################################################################################
    # Sun-Earth axis
    
    append!(paths, drawarrow(-0.5, 0.0, 1.0, 0.0, arrow_head_size))

    #################################################################################
    # Spin-Sun angle
    
    append!(paths, drawarrow(0.0, 0.0, cos(α), sin(α), arrow_head_size))
    append!(paths, drawarc(0.0, 0.0, 0.10, 0.0, α))

    push!(label_array, (0.14 * cos(α/2), 0.14 * sin(α/2), "\\alpha"))

    #################################################################################
    # Boresight-Spin angle

    pt1 = Float64[cos(α + β), sin(α + β)]
    pt2 = Float64[cos(α - β), sin(α - β)]
    append!(paths, drawarrow(0.0, 0.0, pt1[1], pt1[2], arrow_head_size))
    append!(paths, drawarrow(0.0, 0.0, pt2[1], pt2[2], arrow_head_size))

    append!(paths, drawdoublearc(0.0, 0.0, 0.20, 0.22, α, α + β))
    push!(label_array, (0.26 * cos(α + β/2), 0.26 * sin(α + β/2), "\\beta"))

    append!(paths, drawdoublearc(0.0, 0.0, 0.21, 0.23, α - β, α))
    push!(label_array, (0.27 * cos(α - β/2), 0.27 * sin(α - β/2), "\\beta"))

    # Orbit of the spin axis around the Sun-Earth axis (vertical ellipse)
    @series begin
        orbits = []

        # Orbit of the spin axis around the Sun-Earth axis (vertical ellipse)
        append!(orbits, drawrotatedellipse(cos(α), 0.0, 0.1, sin(α), 0.0))

        seriestype := :path
        linecolor := :gray
        line := (0.5, :dash)

        [pt[1] for pt in orbits], [pt[2] for pt in orbits]
    end

    # Orbit of the boresight axis around the spin axis (tilted ellipse)
    @series begin
        orbits = []

        append!(orbits, drawrotatedellipse((pt1[1] + pt2[1]) / 2,
                                           (pt1[2] + pt2[2]) / 2,
                                           sqrt((pt2[1] - pt1[1])^2 + (pt2[2] - pt1[2])^2) / 2,
                                           0.1,
                                           π/2 + α))

        seriestype := :path
        linecolor := :gray
        line := (0.5, :dash)

        [pt[1] for pt in orbits], [pt[2] for pt in orbits]
    end
    
    seriestype := :path
    framestyle := :none
    axis := nothing
    legend := false
    linecolor := :black
    aspect_ratio := 1.0
    annotation := label_array
    
    [pt[1] for pt in paths], [pt[2] for pt in paths]
end

@doc raw"""
    plot(sstr::ScanningStrategy)

Plot a diagram representing the scanning strategy. You must have
loaded the [Plots](https://github.com/JuliaPlots/Plots.jl) package
before running this command.

"""
plot_scanning_strategy
    
################################################################################

function time2pointing!(sstr::ScanningStrategy, time_s, beam_dir, polangle_rad, resultvec)
    curpolang = mod2pi(polangle_rad + 4 * sstr.omega_hwp_hz * time_s)
    # The polarization vector lies on the XY plane; if polangle_rad=0 then
    # the vector points along the X direction at t=0.
    poldir = StaticArrays.SVector(cos(curpolang), sin(curpolang), 0.0)
    
    q2 = qrotation_z(sstr.omega_spin_hz * time_s)
    q4 = qrotation_x(sstr.omega_prec_hz * time_s)
    q5 = qrotation_z(sstr.omega_year_hz * time_s)
    
    qtot = q5 * (q4 * (sstr.q3 * (q2 * sstr.q1)))
    rot = rotationmatrix_normalized(qtot)
    # Direction in the sky of the beam main axis
    resultvec[4:6] = rot * beam_dir
    # Direction in the sky of the beam polarization axis
    poldir = rot * poldir
    
    # The North for a vector v is just -dv/dθ, as θ is the
    # colatitude and moves along the meridian
    (θ, ϕ) = Healpix.vec2ang(resultvec[4:6]...)
    northdir = StaticArrays.SVector(-cos(θ) * cos(ϕ), -cos(θ) * sin(ϕ), sin(θ))
    
    cosψ = clamp(dot(northdir, poldir), -1, 1)
    crosspr = northdir × poldir
    sinψ = clamp(sqrt(dot(crosspr, crosspr)), -1, 1)
    resultvec[3] = atan(cosψ, sinψ)

    resultvec[1], resultvec[2] = θ, ϕ
end

function time2pointing(sstr::ScanningStrategy, time_s, beam_dir, polangle_rad)
    resultvec = Float64[0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    time2pointing!(sstr, time_s, beam_dir, polangle_rad, resultvec)
    resultvec
end

@doc raw"""
    time2pointing!(sstr::ScanningStrategy, time_s, beam_dir, polangle_rad, resultvec)
    time2pointing(sstr::ScanningStrategy, time_s, beam_dir, polangle_rad)

Calculate the pointing direction of a beam along the direction `beam_dir`, with
a detector sensitive to the polarization along the angle `polangle_rad`. The
result is saved in `resultvec` for `time2pointing!`, and it is the return value
of `time2pointing`; it is a 6-element array containing the following fields:

1. The colatitude (in radians) of the point in the sky
2. The longitude (in radians) of the point in the sky
3. The polarization angle, in the reference frame of the sky
4. The X component of the normalized pointing vector
5. The Y component
6. The Z component

Fields #4, #5, #6 are redundant, as they can be derived from the colatitude
(field #1) and longitude (field #2). They are returned as the code already
computes them.

The vector `beam_dir` and the angle `polangle_rad` must be expressed in the
reference system of the focal plane. If `polangle_rad == 0`, the detector
measures polarization along the x axis of the focal plane. The normal direction
to the focal plane is along the z axis; thus, the boresight director is such
that `beam_dir = [0., 0., 1.]`.

"""
time2pointing!, time2pointing

################################################################################

function genpointings!(sstr::ScanningStrategy, timerange_s, beam_dir, polangle_rad, result)
    @assert size(result)[1] == length(timerange_s)

    @inbounds for (idx, t) in enumerate(timerange_s)
        time2pointing!(sstr, t, beam_dir, polangle_rad, view(result, idx, :))
    end
end

function genpointings(sstr::ScanningStrategy, timerange_s, beam_dir, polangle_rad)
    result = Array{Float64}(undef, length(timerange_s), 6)
    genpointings!(sstr, timerange_s, beam_dir, polangle_rad, result)

    result
end

@doc raw"""
    genpointings!(sstr::ScanningStrategy, timerange_s, beam_dir, polangle_rad, result)
    genpointings(sstr::ScanningStrategy, timerange_s, beam_dir, polangle_rad)

Generate a set of pointing directions and angles for a given orientation
`beam_dir` (a 3-element vector) of the boresight beam, assuming the scanning
strategy in `sstr`. The pointing directions are calculated over all the elements
of the list `timerange_s`. The angle `polangle_rad` is the value of the
polarization angle at time ``t = 0``.

The two functions only differ in the way the result is returned to the caller.
Function `genpointings` returns a N×6 matrix containing the following fields:

1. The colatitude (in radians)
2. The longitude (in radians)
3. The polarization angle (in radians)
4. The X component of the one-length pointing vector
5. The Y component
6. The Z component

Function `genpointings!` works like `genpointings`, but it accept a
pre-allocated matrix as input (the `result` parameter) and will save the result
in it. The matrix must have two dimensions with size `(N, 6)` at least.

Both functions are simple iterators wrapping [`time2pointing!`](@ref) and
[`time2pointing`](@ref).

"""
genpointings!, genpointings

################################################################################

@doc raw"""
    struct SegmentedTimeSpan

An immutable structure representing a long time span, split into units
of equal length called *segments*. This structure is typically used to
make consecutive calls to [`genpointings!`](@ref) and
[`genpointings`](@ref).

The fields are the following:

- `start_time` is the time of the first sample in the time span
- `sampling_time` is the integration time for one sample
- `segment_duration` is the duration of one segment
- `num_of_segments` is the number of segments in the time span

The following example defines a time span of 1 year as the composition
of multiple spans, each lasting one day:

```julia
sts = SegmentedTimeSpan(
    start_time = 0.0,
    sampling_time = 0.1,
    segment_duration = 24 * 3600,
    num_of_segments = 365,
)
```

Once a `SegmentedTimeSpan` has been constructed, it behaves like an
array, whose elements are time ranges of type `StepRangeLen`. You can
iterate over it, to run functions like [`genpointings`](@ref):

```julia
for cur_time_span in sts
    pointings = genpointings(PICO_SCANNING_STRATEGY, cur_time_span, ...)

    # "pointings" contain the pointings for the time span
end
```

"""
struct SegmentedTimeSpan
    start_time::Float64
    sampling_time::Float64
    segment_duration::Float64
    num_of_segments::Int

    SegmentedTimeSpan(;
        start_time=0.0,
        sampling_time=1.0,
        segment_duration=3600.0,
        num_of_segments=24,
    ) = new(start_time, sampling_time, segment_duration, num_of_segments)
end

last_time_in_segment(start_time, sts::SegmentedTimeSpan) = start_time + sts.segment_duration - sts.sampling_time

function Base.iterate(iter::SegmentedTimeSpan)
    iter.num_of_segments > 0 || return nothing
    (iter.start_time : iter.sampling_time : last_time_in_segment(iter.start_time, iter),
     iter.start_time + iter.segment_duration)
end

function Base.iterate(iter::SegmentedTimeSpan, start_time)
    start_time >= iter.start_time + iter.segment_duration * iter.num_of_segments && return nothing

    (start_time : iter.sampling_time : last_time_in_segment(start_time, iter),
     start_time + iter.segment_duration)
end

function Base.getindex(sts::SegmentedTimeSpan, idx::Number)
    1 <= idx <= sts.num_of_segments || throw(BoundsError(sts, idx))

    start_time = sts.start_time + sts.segment_duration * (idx - 1)
    start_time : sts.sampling_time : last_time_in_segment(start_time, sts)
end

Base.getindex(sts::SegmentedTimeSpan, I) = [sts[x] for x in I]
Base.length(sts::SegmentedTimeSpan) = sts.num_of_segments
Base.firstindex(sts::SegmentedTimeSpan) = 1
Base.lastindex(sts::SegmentedTimeSpan) = length(sts)
Base.eachindex(sts::SegmentedTimeSpan) = 1:length(sts)
