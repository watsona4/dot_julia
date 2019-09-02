# Pointing generation

One of the most basic facilities provided by CMBMissionSim is the
generation of pointing timelines. CMBMissionSim assumes that the
spacecraft orbits around the L2 Lagrangean point of the Sun-Earth
system, and that it performs a monotonous spin around some axis,
optionally with some precession period. This is a quite rigid scheme,
but it is the one followed by Planck, CORE, and LiteBIRD.

The basic object used to create pointings is the
[`ScanningStrategy`](@ref) structure. You can build a
`ScanningStrategy` object using one of its constructors. The most
basic one takes the following syntax:

```julia
ScanningStrategy(;
    spin_rpm = 0,
    prec_rpm = 0,
    yearly_rpm = 1  / (MINUTES_PER_DAY * DAYS_PER_YEAR),
    hwp_rpm = 0,
    spinsunang_rad = deg2rad(45.0),
    borespinang_rad = deg2rad(50.0),
)
```

Note that this constructor only takes keywords, and that the
measurement units used for them are different from the ones used in
the fields in `ScanningStrategy`. Units in the constructors have been
chosen in order to be easy to use, while units in `ScanningStrategy`
allow to make computations more efficient.

Another kind of constructor allows to load the scanning strategy
definition from a JSON file. It comes in two flavours:

```julia
# First version: pass a file object to `ScanningStrategy`
open("my_scanning_strategy.json", "r") do inpf
    sstr = ScanningStrategy(inpf)
end

# Second version (easier): pass the name of the file
sstr = ScanningStrategy("my_scanning_strategy.json")
```

These JSON files can be created using the function [`save`](@ref):

```julia
sstr = ScanningStrategy(spinsunang_rad = deg2rad(35.0))
save("my_scanning_strategy.json", sstr)
```

If you have loaded the
[Plots.jl](https://github.com/JuliaPlots/Plots.jl) package, you can
produce a rough diagram of the scanning strategy using the `plot`
function on a `ScanningStrategy` object:

```@example plot_scanning_strategy
using Harlequin # hide
using Plots
sstr = ScanningStrategy(
    spinsunang_rad = deg2rad(35.0),
    borespinang_rad = deg2rad(40.0),
)
plot(sstr)
savefig("sstr_plot.svg"); nothing # hide
```

![](sstr_plot.svg)

(Conventionally, the angle between the spin axis and the
Sun-Spacecraft direction is indicated with the symbol α, and the angle
between the boresight direction and the spin axis with β.)

Once you have a [`ScanningStrategy`](@ref) object, you generate the
sequence of pointing directions through one of the following
functions:

- `genpointings` and `genpointings!` generate a set of pointing
  directions that encompass a range of time; most of the time you will
  use this.
- `time2pointing` and `time2pointing!` generate one pointing direction
  at a time; they are useful if you are working on a system with
  limited memory resources.

The version with the `!` and the end save their result in a
preallocated block, while the other ones use the return value of the
function. The former is useful if you are using some strategy to
pre-allocate memory in order to optimize running times. For instance,
the following code is not optimal, as `genpointings` is re-creating
the same result matrix over and over again:

```julia
const SECONDS_IN_A_HOUR = 3600.
sstr = ScanningStrategy()
start_time = 0.0
# Simulate an observation lasting 1000 hours
for hour_num in 1:1000
    # Each call to "genpointings" allocates a new "pnt" matrix:
    # doing it multiple times like in this "for" loop takes time and
    # slows down the execution!
    pnt = genpointings(sstr, start_time:(start_time + SECONDS_IN_A_HOUR),
        Float64[0, 0, 1], 0.0)
    # Use "pnt" here
    # ...
end
```

The code below is more efficient, as the allocation is done only once:

```julia
const SECONDS_IN_A_HOUR = 3600.
sstr = ScanningStrategy()
start_time = 0.0

# Allocate this variable once and for all
pnt = Array{Float64}(undef, SECONDS_IN_A_HOUR, 6)

# Simulate an observation lasting 1000 hours
for hour_num in 1:1000
    # Use "pnt" again and again, overwriting it each time: this is
    # much faster!
    genpointings!(sstr, start_time:(start_time + SECONDS_IN_A_HOUR),
        Float64[0, 0, 1], 0.0, pnt)
    # Use "pnt" here
    # ...
end
```


## `ScanningStrategy`

```@docs
ScanningStrategy
update_scanning_strategy
```

## Pre-defined scanning strategies

Harlequin includes a few constants for the scanning strategies used by
notable CMB proposals.

```@docs
CORE_SCANNING_STRATEGY
PICO_SCANNING_STRATEGY
```

## Generating pointings over long periods of time

Harlequin provides an handy structure, `SegmentedTimeSpan`, which can
be used to produce the time ranges required by [`genpointings`](@ref)
and [`genpointings!`](@ref) in a *segmented* fashion.

Suppose you want to simulate the behavior of a spacecraft over one
year. As the sampling frequency of the detector is small, one tenth of
a second, the pointing matrix returned by [`genpointings`](@ref) is
going to be huge. Usually there is no need to keep all the pointing
matrix at once; typically what you want to keep is the pixel index for
each sample and the polarisation angle.

In this case, you can divide the overall time span (one year) into
small segments and process one of them at a time, using
`SegmentedTimeSpan`. The following example shows the idea: we simulate
one day of observations one hour at a time.

```@example segmented_time_span
using Harlequin # hide
sts = SegmentedTimeSpan(
    start_time = 0.0,
    sampling_time = 0.1,
    segment_duration = 3600,  # One hour
    num_of_segments = 24,     # One day of observations
)

# Each element of the "sts" array is the sequence of time samples
# for one day

# Size the pointing matrix according to the first day
pointings = Array{Float64}(undef, length(sts[1]), 6)

for (hour_number, cur_time_span) in enumerate(sts)
    println("Processing hour #$hour_number, time samples are $cur_time_span")
    genpointings!(
        PICO_SCANNING_STRATEGY,
        cur_time_span,
        Float64[0, 0, 1],
        0.0,
        pointings,
    )
    
    # "pointings" contains the pointings for the current hour
end
```

```@docs
SegmentedTimeSpan
```

## Loading and saving scanning strategies

```@docs
load_scanning_strategy
to_dict
save
```

## Pointing generation

```@docs
time2pointing
time2pointing!
genpointings
genpointings!
```

## Utility functions

```@docs
rpm2angfreq
angfreq2rpm
period2rpm
rpm2period
```
