# API Documentation and Usage

Once the Dubins package is installed it can be imported using the command
```julia
using Dubins
```
The methods that can be used without the qualifier `Dubins.` include
```
dubins_shortest_path, dubins_path,
dubins_path_length, dubins_segment_length,
dubins_segment_length_normalized,
dubins_path_type, dubins_path_sample,
dubins_path_sample_many, dubins_path_endpoint,
dubins_extract_subpath
```
The constants and other variables that can be used without the qualifier `Dubins.` include
```
DubinsPathType, SegmentType, DubinsPath,
LSL, LSR, RSL, RSR, RLR, LRL,
EDUBOK, EDUBCOCONFIGS, EDUBPARAM,
EDUBBADRHO, EDUBNOPATH, EDUBBADINPUT
```

Any method in the Dubins package would return an error code. The error codes that are defined within the package are
```julia
const EDUBOK = 0                # no error
const EDUBCOCONFIGS = 1         # colocated configurations
const EDUBPARAM = 2             # path parameterization error
const EDUBBADRHO = 3            # the rho value is invalid
const EDUBNOPATH = 4            # no connection between configurations with this word
const EDUBBADINPUT = 5          # uninitialized inputs to functions
```

## Dubins paths/shortest Dubins path
The shortest path between two configurations is computed using the method `dubins_shortest_path()` as
```julia
errcode, path = dubins_shortest_path([0.0, 0.0, 0.], [1., 0.0, 0.], 1.)
```
Here, path is an object of type `DubinsPath`, `[0.0, 0.0, 0.]` is the initial configuration, `[1., 0.0, 0.]` is the final configuration and `1.` is the turn radius of the Dubins vehicle. A configuration is a 3-element vector with the x-coordinate, y-coordinate, and the heading angle.
The above code would return a non-zero error code in case of any errors. If the error code is non-zero, then `nothing` is returned for the path.

A Dubins path of a specific type can be computed using
```julia
errcode, path = dubins_path(zeros(3), [10.0, 0.0, 0.], 1., RSL)
```
where, the last argument is the type of Dubins path; it can take any value in `LSL, LSR, RSL, RSR, RLR, LRL`. Again here, tf the error code is non-zero, then `nothing` is returned for the path.

The length of a Dubins path is computed after a function call to `dubins_shortest_path()` or `dubins_path()` as
```julia
val = dubins_path_length(path)
```

The length of each segment (1-3) in a Dubins path and the type of Dubins path can be queried using
```julia
val1 = dubins_segment_length(path, 1)
val2 = dubins_segment_length(path, 2)
val3 = dubins_segment_length(path, 3)
path_type = dubins_path_type(path)
```
The second argument in the method `dubins_segment_length()` is the segment number. If a segment number that is less than 1 or greater than 3 is used, the method will return `Inf`.

## Sub-path extraction
A sub-path of a given Dubins path can be extracted as
```julia
errcode, path = dubins_path(zeros(3), [4., 0.0, 0.], 1., LSL)

errcode, subpath = dubins_extract_subpath(path, 2.)
```
The second argument of the function `dubins_extract_subpath()` is a parameter that has to lie in the interval `[0,dubins_path_length(path)]`, failing which the function will return a `EDUBPARAM` error-code and a `nothing` for the path

After extracting a sub-path, the end-point of the sub-path can be queried using the method `dubins_path_endpoint(subpath)`,. This function returns `EDUBOK` on successful completion and a 3-element vector representing the configuration of the end-point of the sub-path.

## Sampling a Dubins path
Sampling the configurations along a Dubins path is a useful feature that can aid in writing additional plotting features. To that end, the package includes two functions that can achieve the same goal of sampling in two different ways; they are `dubins_path_sample()` and `dubins_path_sample_many()`. The usage of the method `dubins_path_sample()` is illustrated by the following code snippet:
```julia
errcode, path = dubins_path([0.0, 0.0, 0.], [4., 0.0, 0.], 1., LSL)

errcode, qsamp = dubins_path_sample(path, 0.)
# qsamp will take a value [0.0, 0.0, 0.], which is the initial configuration
# the call to dubins_path_sample() should always be preceded by a successful call to dubins_path() or dubins_shortest_path()

errcode, qsamp = dubins_path_sample(path, 4.)
# qsamp will take a value [4., 0.0, 0.], which is the final configuration

errcode, qsamp = dubins_path_sample(path, 2.)
# qsamp will take a value [2., 0.0, 0.], the configuration of the vehicle after travelling for 2 units
```
The second argument of the function `dubins_path_sample()` is a parameter that has to lie in the interval `[0,dubins_path_length(path)]`, failing which the function will return a `EDUBPARAM` error-code and `nothing`  

As one can observe from the above code snippet, `dubins_path_sample()` samples the Dubins path only once. Sampling an entire Dubins path using a step size, can be achieved using the method `dubins_path_sample_many()`. The `dubins_path_sample_many()` takes in two arguments:

1. the Dubins path that needs to be sampled, and
2. the step size denoting the distance along the path for subsequent samples.

The following code snippet samples a Dubins path using a step size:
```julia
errcode, path = dubins_path([0.0, 0.0, 0.], [4., 0.0, 0.], 1., LSL)
errcode, configurations = dubins_path_sample_many(path, 1.)
```

The output of the above code snippet is
```
julia> errcode
0
julia> configurations
4-element Array{Any,1}:
 [0.0, 0.0, 0.0]
 [1.0, 0.0, 0.0]
 [2.0, 0.0, 0.0]
 [3.0, 0.0, 0.0]
```

The same behaviour can also be achieved by using the `dubins_path_sample()` multiple times, one for each step. For more examples, the readers are refered to the unit tests in the file `test/test_api.jl`.
