# TimeSeriesResampler

[![Package Evaluator](http://pkg.julialang.org/badges/TimeSeriesResampler_0.6.svg)](http://pkg.julialang.org/?pkg=TimeSeriesResampler)

[![Build Status](https://travis-ci.org/femtotrader/TimeSeriesResampler.jl.svg?branch=master)](https://travis-ci.org/femtotrader/TimeSeriesResampler.jl)

[![Build status](https://ci.appveyor.com/api/projects/status/github/femtotrader/timeseriesresampler.jl?svg=true&branch=master)](https://ci.appveyor.com/project/femtotrader/timeseriesresampler-jl/branch/master)

[![Coverage Status](https://coveralls.io/repos/github/femtotrader/TimeSeriesResampler.jl/badge.svg?branch=master)](https://coveralls.io/github/femtotrader/TimeSeriesResampler.jl?branch=master)

[![codecov.io](http://codecov.io/github/femtotrader/TimeSeriesResampler.jl/coverage.svg?branch=master)](http://codecov.io/github/femtotrader/TimeSeriesResampler.jl?branch=master)

A Julia package to resample timeseries (from [TimeSeries.jl](http://juliastats.github.io/TimeSeries.jl/stable/))

## Install

```julia
Pkg.add("TimeSeriesResampler")
```

## Usage

### Get sample data from [MarketData.jl](https://github.com/JuliaQuant/MarketData.jl)

```julia
julia> using MarketData: AAPL

julia> using Dates

julia> using TimeSeriesResampler

julia> ta = AAPL
8336x12 TimeSeries.TimeArray{Float64,2,Date,Array{Float64,2}} 1980-12-12 to 2013-12-31

             Open      High      Low       Close     Volume          Ex-Dividend  Split Ratio  Adj. Open  Adj. High  Adj. Low  Adj. Close  Adj. Volume
1980-12-12 | 28.75     28.88     28.75     28.75     2093900         0.0          1            3.3766     3.3919     3.3766    3.3766      16751200
1980-12-15 | 27.38     27.38     27.25     27.25     785200          0.0          1            3.2157     3.2157     3.2004    3.2004      6281600
1980-12-16 | 25.38     25.38     25.25     25.25     472000          0.0          1            2.9808     2.9808     2.9655    2.9655      3776000
1980-12-17 | 25.88     26.0      25.88     25.88     385900          0.0          1            3.0395     3.0536     3.0395    3.0395      3087200
⋮
2013-12-26 | 568.1     569.5     563.38    563.9     7286000         0.0          1            564.7392   566.1309   560.0471  560.564     7286000
2013-12-27 | 563.82    564.41    559.5     560.09    8067300         0.0          1            560.4845   561.071    556.1901  556.7766    8067300
2013-12-30 | 557.46    560.09    552.32    554.52    9058200         0.0          1            554.1621   556.7766   549.0525  551.2395    9058200
2013-12-31 | 554.17    561.28    554.0     561.02    7967300         0.0          1            550.8916   557.9595   550.7226  557.7011    7967300
```

### Resample monthly volume (using `sum`)

```julia
julia> sum(resample(ta[:Volume], Dates.Month(1)))
397x1 TimeSeries.TimeArray{Float64,1,Date,Array{Float64,1}} 1980-12-01 to 2013-12-01

             Volume
1980-12-01 | 6003800
1981-01-01 | 2718700
1981-02-01 | 1435800
1981-03-01 | 3128200
⋮
2013-09-01 | 308247900
2013-10-01 | 279919000
2013-11-01 | 186612700
2013-12-01 | 252049900
```

### Resample monthly adjusted close price (using `ohlc`)

```julia
julia> ohlc(resample(ta[Symbol("Adj. Close")], Dates.Month(1)))
397x4 TimeSeries.TimeArray{Float64,2,Date,Array{Float64,2}} 1980-12-01 to 2013-12-01

             Open      High      Low       Close
1980-12-01 | 3.3766    4.2281    2.9655    4.0073
1981-01-01 | 4.0519    4.0519    3.3179    3.3179
1981-02-01 | 3.1264    3.3766    2.7894    3.1123
1981-03-01 | 3.1264    3.1417    2.5392    2.8774
⋮
2013-09-01 | 482.8624  500.2466  444.8525  471.1709
2013-10-01 | 482.2497  525.6854  475.3118  516.5832
2013-11-01 | 513.9444  552.7803  509.4582  552.7803
2013-12-01 | 547.969   566.7174  541.239   557.7011
```

### Resample monthly adjusted close price (using `mean`)

```julia
julia> mean(resample(ta[Symbol("Adj. Close")], Dates.Month(1)))
397x1 TimeSeries.TimeArray{Float64,1,Date,Array{Float64,1}} 1980-12-01 to 2013-12-01

             Adj. Close
1980-12-01 | 3.5752
1981-01-01 | 3.7178
1981-02-01 | 3.1013
1981-03-01 | 2.9166
⋮
2013-09-01 | 474.5652
2013-10-01 | 498.8381
2013-11-01 | 521.058
2013-12-01 | 556.3467
```

### Under the hood...

TimeSeriesResampler uses TimeFrame from [TimeFrames.jl](https://github.com/femtotrader/TimeFrames.jl/) for resampling.

TimeFrames can be set using:

- `Dates.DatePeriod` such as `Dates.Month(1)`
- `Dates.TimePeriod` such as `Dates.Hour(1)`
- String shortcuts for timeframe (`"A"`, `"AS"`, `"M"`, `"MS"`, `"W"`, `D`, `"5H"`, ...)
- Lambda functions to define how `Date` and/or `DateTime` should be grouped (ie `dt -> floor(dt, Dates.Month(1))`)
- Named timeframe (such as `YearEnd(1)`, `Week(1)`, ...) - `using TimeFrames` is required (don't use `using Base: Dates`)
 
An example with end of month (`MonthEnd()`) volume (`sum`) resampling

```julia
julia> using MarketData: AAPL

julia> using TimeFrames

julia> using TimeSeriesResampler

julia> ta=AAPL
8336x12 TimeSeries.TimeArray{Float64,2,Date,Array{Float64,2}} 1980-12-12 to 2013-12-31

             Open      High      Low       Close     Volume          Ex-Dividend  Split Ratio  Adj. Open  Adj. High  Adj. Low  Adj. Close  Adj. Volume
1980-12-12 | 28.75     28.88     28.75     28.75     2093900         0.0          1            3.3766     3.3919     3.3766    3.3766      16751200
1980-12-15 | 27.38     27.38     27.25     27.25     785200          0.0          1            3.2157     3.2157     3.2004    3.2004      6281600
1980-12-16 | 25.38     25.38     25.25     25.25     472000          0.0          1            2.9808     2.9808     2.9655    2.9655      3776000
1980-12-17 | 25.88     26.0      25.88     25.88     385900          0.0          1            3.0395     3.0536     3.0395    3.0395      3087200
⋮
2013-12-26 | 568.1     569.5     563.38    563.9     7286000         0.0          1            564.7392   566.1309   560.0471  560.564     7286000
2013-12-27 | 563.82    564.41    559.5     560.09    8067300         0.0          1            560.4845   561.071    556.1901  556.7766    8067300
2013-12-30 | 557.46    560.09    552.32    554.52    9058200         0.0          1            554.1621   556.7766   549.0525  551.2395    9058200
2013-12-31 | 554.17    561.28    554.0     561.02    7967300         0.0          1            550.8916   557.9595   550.7226  557.7011    7967300


julia> sum(resample(ta[:Volume], MonthEnd()))
397x1 TimeSeries.TimeArray{Float64,1,Date,Array{Float64,1}} 1980-12-31 to 2013-12-31

             Volume
1980-12-31 | 6003800
1981-01-31 | 2718700
1981-02-28 | 1435800
1981-03-31 | 3280300
⋮
2013-09-30 | 320886600
2013-10-31 | 277097800
2013-11-30 | 176795200
2013-12-31 | 252049900
```
