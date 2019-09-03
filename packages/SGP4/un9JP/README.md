# SGP4.jl

[![Build Status](https://travis-ci.org/crbinz/SGP4.jl.svg?branch=master)](https://travis-ci.org/crbinz/SGP4.jl)

*NOTE*: Consider using the pure-julia SGP4 implementation in [SatelliteToolbox.jl](https://github.com/JuliaSpace/SatelliteToolbox.jl#sgp4). 

This package enables satellite orbit propagation using the [SGP4](https://en.wikipedia.org/wiki/Simplified_perturbations_models) models, given the satellites two-line element set ([TLE](http://www.celestrak.com/NORAD/documentation/tle-fmt.asp)). For now, this is a simple wrapper of [python-sgp4](https://github.com/brandon-rhodes/python-sgp4) using [PyCall.jl](https://github.com/stevengj/PyCall.jl). There are several small changes from `python-sgp4`:

1. Gravity coefficients are loaded into a `GravityModel` type. For instance, to load the WGS-72 coefficients, just do `GravityModel("wgs72")`. The other two options are "wgs72old" and "wgs84".

2. Propagation is a standalone function, as opposed to a `satellite` member function. So, propagation is accomplished by `propagate( sat, year, month, day, hour, min, sec)`.

## Usage
Following the example given [here](https://pypi.python.org/pypi/sgp4/), the TEME position and velocity for Vanguard 1 at 12:50:19 on 29 June 2000 may be calculated by:

```
using SGP4
line1 = "1 00005U 58002B   00179.78495062  .00000023  00000-0  28098-4 0  4753"
line2 = "2 00005  34.2682 348.7242 1859667 331.7664  19.3264 10.82419157413667"
wgs72 = GravityModel("wgs72")
satellite = twoline2rv(line1, line2, wgs72)
(position, velocity) = propagate(satellite, 2000, 6, 29, 12, 50, 19)
```

`satellite` attributes, such as the TLE epoch, may be accessed as `satellite[:epoch]`.

You can also generate an ephemeris, given a TLE, start date/time, stop date/time, and time step:

```
(positions, velocities) = propagate(satellite, Dates.DateTime("2000-06-29T12:50:19.000"), Dates.DateTime("2000-06-30T12:50:19.000"), Dates.Second(60))
```

For more examples, see `test/runtests.jl`.

For other documentation, see [this page](https://pypi.python.org/pypi/sgp4/).
