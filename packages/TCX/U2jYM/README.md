[![Build Status](https://travis-ci.com/xue35/TCX.jl.svg?branch=master)](https://travis-ci.com/xue35/TCX.jl)
[![Coverage Status](https://coveralls.io/repos/github/xue35/TCX.jl/badge.svg?branch=master)](https://coveralls.io/github/xue35/TCX.jl?branch=master)

# TCX.jl
TCX.jl intends to provide an list of Julia modules to access Training Center XML(TCX) files. This project is inspired by [vkurup/python-tcxparser](https://github.com/vkurup/python-tcxparser).

# Installation
```julia
julia> using Pkg; Pkg.add("TCX");
```

# Usage

### Basic usage
```julia
using TCX

err, tcx = TCX.parse_tcx_file("my_marathon.tcx")
println(getDistance(tcx)) # Static distance record in TCX activity header.
println(getDistance2(tcx)) # Distance calculated out of tackpoints using Geodesty
println(getDuration(tcx))
println(getAverageSpeed(tcx))
println(getAveragePace(tcx))

```

### Load multiple TCX for analysis
```julia
using TCX, DataFrames
err, tcxArray = TCX.parse_tcx_dir("/my_running_logs/")
get_DataFrame(tcxArray)

```
# License
MIT License

# Contact
Please contact me if any question or comment.

# Ref
* [Garmin's Training Center Database XML (TCX) Schema](http://www8.garmin.com/xmlschemas/TrainingCenterDatabasev2.xsd)
* [User profile extension Schema](http://www8.garmin.com/xmlschemas/UserProfileExtensionv1.xsd)
* [Activity extension schema](Activity extension Schema)

