# SDWBA

```@contents
```

This Julia package implements the (stochastic) distorted-wave Born approximation for simple, fluid-like scatterers. The goal is to provide a set of easy-to-use tools to calculate the acoustic backscattering cross-sections of marine organisms using the (stochastic) distorted-wave Born approximation (the DWBA or SWDBA). These models discretize zooplankton or other scatterers as a series of cylindrical sections, and are efficient and accurate for fluid-like organisms, including krill and copepods.

## Installation
To install, run

```julia
Pkg.add("SDWBA")
```

It can then be loaded the normal way:

```julia
using SDWBA
```

## Basic use

### Constructing Scatterers

Sound-scattering things (e.g. zooplankton) are represented as `Scatterer` objects.  A `Scatterer` contains information about the shape and material properties of such an object.  The (S)DWBA assumes the a deformed cylindrical shape: circular in cross-section, with a varying radius and a centerline that doesn't need to be straight.  A `Scatterer` represents this shape as a series of discrete segments.

To construct a scatterer, we need to specify the 3-D coordinates of its centerline.  The standard orientation is for the animal's body to lie roughly parallel to the x-axis, with the z-axis pointing up.

```julia
x = range(0, stop=0.2, length=10)
y = zeros(x)
z = zeros(x)
```

These coordinates are stacked into a 3xN matrix, which will be called `r`.

```julia
r = [x'; y'; z']
```

The scatterer's radius can vary as well.  We'll make ours kinda lumpy.

```julia
a = randn(10).^2  # squared to make sure the're all positive
```

We also define the density and sound-speed contrasts *h* and *g* (value inside scatterer / value in the surrounding medium).  These can vary from one segmen to another, but will often be assumed constant inside the scatterer.

```julia
h = 1.02 * ones(a)
g = 1.04 * ones(a)
```

We can now define the scatterer.

```Julia
weird_zoop = Scatterer(r, a, h, g)
```

### Loading Scatterers from file

A function `from_csv()` is provided to load a scatterer directly from a comma-separated datafile.  This file should have columns for the x, y, z, a, g, and h values of the scatterer.  If the columns have those names, the function will work automatically:

```julia
my_scat = from_csv("path/to/my_scat.csv")
```

If the columns have some other names, you can provide a dictionary telling the function which is which.

```julia
colnames = Dict([("x","foo"),("y","bar"),("z","baz"), ("a","qux"),
	("h","plugh"), ("g","garply")])
my_scat = from_csv("path/to/my_scat.csv", colnames)

```

### Build-in models

The package comes with a sub-module called `Models` containing several ready-made `Scatterer`s.  See the documentation for references for each one.

```julia
krill = Models.krill_mcgeehee
```


### Calculating backscatter

There are three functions that calculate backscatter: `form_function`, `backscatter_xsection`, and `target_strength`.  Each is just a wrapper around the one before it, and they all have the same arguments.

```julia
krill = Models.krill_mcgeehee
freq = 120e3 # Hz
sound_speed = 1470 # m/s

# deterministic DWBA
target_strength(krill, freq, sound_speed)

# stochastic SDWBA
phase_sd = 0.7071
target_strength(krill, freq, sound_speed, phase_sd)
```

When a frequency and sound speed are provided, the sound is assumed to come from above, as is the usual case with a ship-mounted echosounder.  If you would like it to come from some other direction, you can specify a 3-D wavenumber vector--that is, a vector, pointing in the direction of propagation, whose magnitude is $k = 2 pi f / c$.

```julia
k_mag = 2pi * freq / sound_speed
k_vertical = [0.0, 0.0, -k_mag]
target_strength(krill, k_vertical)

angle = deg2rad(30)
k_slanted = k_mag * [sin(angle), 0, cos(angle)]
target_strength(krill, k_slanted)
```

It is usually easier to think of the scatterer tilting than the wavenumber vector.  The `rotate` function does this easily, accepting roll, tilt, and yaw angles (in degrees) as keyword arguments.

```julia
target_strength(rotate(krill, tilt=30), freq, sound_speed)
target_strength(rotate(krill, tilt=45, roll=10), freq, sound_speed)
```

#### Frequency and tilt-angle spectrums

Often, we are interested in calculating the target strength of a scatter over a range of frequencies or angles.  Two convenience functions are provided to do this: `freq_spectrum` and `tilt_spectrum`.  Both return a dictionary, with results in both the linear and log domains.


```julia
start, stop = 10e3, 1000e3 # endpoints of the spectrum, in Hz
nfreqs = 200
fs = freq_spectrum(krill, start, stop, sound_speed, nfreqs)

require(:PyPlot)
semilogx(fs["freqs"], fs["TS"])


ts = tilt_spectrum(krill, -180, 180, k_vertical, 360)

```
