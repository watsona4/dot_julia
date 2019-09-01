# TimeFrames

[![Package Evaluator](http://pkg.julialang.org/badges/TimeFrames_0.6.svg)](http://pkg.julialang.org/?pkg=TimeFrames)

[![Build Status](https://travis-ci.org/femtotrader/TimeFrames.jl.svg?branch=master)](https://travis-ci.org/femtotrader/TimeFrames.jl)

[![Coverage Status](https://coveralls.io/repos/femtotrader/TimeFrames.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/femtotrader/TimeFrames.jl?branch=master)

[![codecov.io](http://codecov.io/github/femtotrader/TimeFrames.jl/coverage.svg?branch=master)](http://codecov.io/github/femtotrader/TimeFrames.jl?branch=master)

A Julia library that defines TimeFrames (essentially for resampling TimeSeries).

## Install

```julia
julia> Pkg.add("TimeFrames")
```

## Usage

```julia
julia> using TimeFrames

julia> tf = TimeFrame("5T")
TimeFrames.Minute(5 minutes,Begin::TimeFrames.Boundary = 1)

julia> apply(tf, DateTime(2016, 9, 11, 20, 9))
2016-09-11T20:05:00

julia> apply(TimeFrame("2H"), DateTime(2016, 9, 11, 20, 9))
2016-09-11T20:00:00
```

This library is used by

- [TimeSeriesResampler.jl](https://github.com/femtotrader/TimeSeriesResampler.jl)
- [TimeSeriesIO.jl](https://github.com/femtotrader/TimeSeriesIO.jl)
