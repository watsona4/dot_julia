# LeapSeconds

*Leap seconds in Julia*

[![Build Status](https://travis-ci.org/JuliaTime/LeapSeconds.jl.svg?branch=master)](https://travis-ci.org/JuliaTime/LeapSeconds.jl) [![Windows Build Status](https://ci.appveyor.com/api/projects/status/b3b6ji2bo70448ex?svg=true)](https://ci.appveyor.com/project/helgee/leapseconds-jl) [![codecov.io](http://codecov.io/github/JuliaTime/LeapSeconds.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaTime/LeapSeconds.jl?branch=master)

**A new minor version of this package will be published everytime a new leap second
is issued be the [IERS](https://www.iers.org/IERS/EN/Home/home_node.html) and dependent
packages will need to be updated!**

## Installation

```julia
pkg> add LeapSeconds
```

## Usage

The package exports a single function `offset_tai_utc` which returns the offset
between International Atomic Time (TAI) and Coordinated Universal Time (UTC)
for a given date. For dates after 1972-01-01, this is the number of leap seconds.

```julia
using LeapSeconds
using Dates

dt = DateTime(2017, 1, 1)

# Pass a `DateTime` instance...
offset_tai_utc(dt)

# ...or a Julian Date
offset_tai_utc(datetime2julian(dt))
```
