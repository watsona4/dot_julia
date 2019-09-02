# Practical examples

In this section, we present a number of examples that show how to use
Harlequin in a number of practical situations. All the examples are
meant to be short and easy to follow; the ideas provided here can help
the reader in build more complex scripts and simulations.


## Scanning strategy

### Creating a scanning strategy

In this exercise, we take the definition of the scanning strategy of a
CMB space mission and create a [`ScanningStrategy`](@ref) object.

We choose the scanning strategy devised for the [PICO mission
proposal](https://ui.adsabs.harvard.edu/abs/2019arXiv190210541H/abstract)
(Hanany, 2019), described in Sect. 4.1.2. Once we have created the
object, we use the [`Plots`](https://github.com/JuliaPlots/Plots.jl)
package to draw a diagram:

```@example pico_scanning_strategy
using Harlequin # hide
sstr = ScanningStrategy(
    spin_rpm = 1,
    prec_rpm = 1 / (10 * 60),      # Precession period is 10 hr
    hwp_rpm = 0.0,                 # No half-wave plate for PICO
    spinsunang_rad = deg2rad(26),
    borespinang_rad = deg2rad(69),
)

using Plots # hide
plot(sstr)
```

This matches Fig. 4.2 in the PICO report.

Note that Harlequin already provides a few [`ScanningStrategy`]
objects for some notable CMB space proposals (see [Pre-defined
scanning strategies](@ref)).

### Generating a sequence of pointings

You can use the function [`genpointings!`](@ref) to produce a matrix
containing the colatitude, longitude, and polarization angle for each
sample in a span of time.

In the following example we generate 5 minutes of data, using the
scanning strategy of the CORE mission proposal and assuming that the
beam is along the boresight direction. We sample the pointing
direction once every 0.1 s:

```@example core_pointings
using Harlequin # hide
using Plots

time_span = 0 : 0.1 : 5 * 60
result = genpointings(
    CORE_SCANNING_STRATEGY,
    time_span,
    Float64[0, 0, 1],         # Beam direction
    0.0,                      # Start value for the polarization angle psi
)

theta, phi, psi, x, y, z = (result[:, colidx] for colidx in 1:6)

plot(time_span, rad2deg.(theta), label="",
     xlabel="Time [s]", ylabel="Colatitude [deg]")
```

### Producing a hit map

Producing a hit map usually requires to consider huge spans of
time. Therefore, it is advisable to pre-allocate the pointing matrix
and use [`genpointings!`](@ref) instead of [`genpointings`](@ref)
within a `for` loop.

We follow the example above ([Generating a sequence of
pointings](@ref)), but this time we use the PICO scanning strategy. We
simulate one day of observations with a beam aligned along the
boresight direction, and we produce a Healpix map with `NSIDE = 256`,
using the [Healpix.jl](https://github.com/ziotom78/Healpix.jl)
package. Note that we take advantage of [`SegmentedTimeSpan`](@ref) to
split the day into segments of 24 hours.

```@example pico_hitmap
using Harlequin # hide
using Healpix
using Plots     # To use "plot" with Healpix maps

sts = SegmentedTimeSpan(
    start_time = 0.0,
    sampling_time = 0.1,
    segment_duration = 3600,  # One hour
    num_of_segments = 24,     # One day of observations
)

hitmap = Map{Float16, RingOrder}(256)

beam_dir = Float64[0, 0, 1]   # Boresight direction

pointings = Array{Float64}(undef, length(sts[1]), 6)

# Loop over each hour
for cur_timespan_s in sts
    genpointings!(
        PICO_SCANNING_STRATEGY, 
        cur_timespan_s, 
        beam_dir, 
        0.0, 
        pointings,   # The result is saved here
    )

    # Project the pointings on the sky sphere
    theta, phi = (pointings[:, colidx] for colidx in (1, 2))
    pixidx = ang2pix.(Ref(hitmap), theta, phi)
    hitmap[pixidx] .= 1
end

# Show the hitmap
plot(hitmap)
```

### Estimating the fraction of sky covered by a scanning strategy

In this example, we produce a plot which shows the fraction of the sky
covered by the CORE scanning strategy as a function of time. It takes
a number of ideas from the examples shown above.

```@example core_fsky
using Harlequin # hide
using Healpix
using Plots

sts = SegmentedTimeSpan(
    start_time = 0.0,
    sampling_time = 0.1,
    segment_duration = 60,   # One minute
    num_of_segments = 60,    # One hour of observations
)

hitmap = Map{Float16, RingOrder}(512)

beam_dir = Float64[0, 0, 1]   # Boresight direction

pointings = Array{Float64}(undef, length(sts[1]), 6)

mins = Int64[]  # This will hold the minutes (X axis of the plot)
fsky = Float64[] # This will hold the sky fraction (Y axis)

# Loop over each minute
for (cur_min, cur_timespan_s) in enumerate(sts)
    genpointings!(
        CORE_SCANNING_STRATEGY, 
        cur_timespan_s, 
        beam_dir, 
        0.0, 
        pointings,   # The result is saved here
    )

    # Project the pointings on the sky sphere
    theta, phi = (pointings[:, colidx] for colidx in (1, 2))
    pixidx = ang2pix.(Ref(hitmap), theta, phi)
    hitmap[pixidx] .= 1
    
    cur_fsky = length(hitmap[hitmap .> 0]) / length(hitmap)
    push!(mins, cur_min)
    push!(fsky, cur_fsky)
end

# Show the hitmap
plot(mins, fsky .* 100, label="",
     xlabel="Time [min]", ylabel="Sky fraction [%]")
```


## Noise simulations

### Running a Monte Carlo simulation

To be written!

## Map-making

To be written!
