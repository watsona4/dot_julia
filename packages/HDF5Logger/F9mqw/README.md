# HDF5Logger

[![Build Status](https://travis-ci.org/tuckermcclure/HDF5Logger.jl.svg?branch=master)](https://travis-ci.org/tuckermcclure/HDF5Logger.jl)
[![Appveyor Build Status](https://ci.appveyor.com/api/projects/status/github/tuckermcclure/HDF5Logger.jl?svg=true)](https://ci.appveyor.com/project/tuckermcclure/hdf5logger-jl)
[![codecov.io](http://codecov.io/github/tuckermcclure/HDF5Logger.jl/coverage.svg?branch=master)](http://codecov.io/github/tuckermcclure/HDF5Logger.jl?branch=master)
<!-- [![Coverage Status](https://coveralls.io/repos/tuckermcclure/HDF5Logger.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/tuckermcclure/HDF5Logger.jl?branch=master) -->

This package creates a logger for storing individual frames of data over time. The frames can be scalars or arrays of any dimension, and the size must be fixed from sample to sample. Further, the total number of samples to log for each source must be known in advance. This keeps the logging very fast. It's useful, for instance, when one is running a simulation, some value in the sim needs to be logged every X seconds, and the end time of the simulation is known, so the total number of samples that will be needed is also known.

## Simple Example

Create a logger. This actually creates and opens the HDF5 file.

```julia
using HDF5Logger
log = Log("my_log.h5")
```

Add a couple of streams. Suppose we'll log a 3-element gyro reading and a 3-element accelerometer signal each a total of 100 times.

```julia
num_samples = 100
example_gyro_reading = [0., 0., 0.]
example_accel_reading = [0., 0., 0.]

# Preallocate space for these signals.
add!(log, "/sensors/gyro",  example_gyro_reading, num_samples)
add!(log, "/sensors/accel", example_accel_reading, num_samples)
```

Log the first sample of each.

```julia
log!(log, "/sensors/gyro",  [1., 2., 3.])
log!(log, "/sensors/accel", [4., 5., 6.])
# We can now log to each of these signals 99 more times.
```

Always clean up.
```julia
close!(log);
```

Did that work?

```julia
using HDF5 # Use the regular HDF5 package to load what we logged.
h5open("my_log.h5", "r") do file
    gyro_data  = read(file, "/sensors/gyro")
    accel_data = read(file, "/sensors/accel")
    display(gyro_data[:,1])
    display(accel_data[:,1])
end
```

```
3-element Array{Float64,1}:
1.00
2.00
3.00
3-element Array{Float64,1}:
4.00
5.00
6.00
```
Yep!

The same process works with scalars, matrices, integers, etc.
