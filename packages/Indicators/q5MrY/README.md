[![Build Status](https://travis-ci.org/dysonance/Indicators.jl.svg?branch=master)](https://travis-ci.org/dysonance/Indicators.jl)
[![Coverage Status](https://coveralls.io/repos/dysonance/Indicators.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/dysonance/Indicators.jl?branch=master)
[![codecov.io](http://codecov.io/github/dysonance/Indicators.jl/coverage.svg?branch=master)](http://codecov.io/github/dysonance/Indicators.jl?branch=master)

[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://dysonance.github.io/Indicators.jl/latest)

# Indicators

Indicators is a [Julia](https://julialang.org) package offering efficient implementations of many technical analysis indicators and algorithms. This work is inspired by the [TTR](https://github.com/joshuaulrich/TTR) package in [R](https://www.r-project.org/) and the [Python](https://www.python.org/) implementation of [TA-Lib](https://github.com/mrjbq7/ta-lib), and the ultimate goal is to implement all of the functionality of these offerings (and more) in Julia. This package has been written to be able to interface with both native Julia `Array` types, as well as the `TS` time series type from the [Temporal](https://github.com/dysonance/Temporal.jl) package. Contributions are of course always welcome for wrapping any of these functions in methods for other types and/or packages out there, as are suggestions for other indicators to add to the lists below.

## Implemented
### Moving Averages
- SMA (simple moving average)
- WMA (weighted moving average)
- EMA (exponential moving average)
- TRIMA (triangular moving average)
- KAMA (Kaufman adaptive moving average)
- MAMA (MESA adaptive moving average, developed by John Ehlers)
- HMA (Hull moving average)
- ALMA (Arnaud-Legoux moving average)
- SWMA (sine-weighted moving average)
- DEMA (double exponential moving average)
- TEMA (triple exponential moving average)
- ZLEMA (zero-lag exponential moving average)
- MMA (modified moving average)
- MLR (moving linear regression)
    - Prediction
    - Slope
    - Intercept
    - Standard error
    - Upper & lower bound
    - R-squared

### Momentum Indicators
- Momentum (n-day price change)
- ROC (rate of change)
- MACD (moving average convergence-divergence)
- RSI (relative strength index)
- ADX (average directional index)
- Parabolic SAR (stop and reverse)
- Fast & slow stochastics
- SMI (stochastic momentum indicator)
- KST (Know Sure Thing)
- Williams %R
- CCI (commodity channel index)
- Donchian channel
- Aroon indicator + oscillator

### Volatility Indicators
- Bollinger Bands
- Average True Range
- Keltner Bands

### Other
- Rolling/running mean
- Rolling/running standard deviation
- Rolling/running variance
- Rolling/running covariance
- Rolling/running correlation
- Rolling/running maximum
- Rolling/running minimum
- Rolling/running MAD (mean absolute deviation)
- Rolling/running quantiles


## Todo
- ~~Moving Linear Regression~~
- ~~KAMA (Kaufman adaptive moving average)~~
- ~~DEMA (double exponential moving average)~~
- ~~TEMA (tripe exponential moving average)~~
- ~~ALMA (Arnaud Legoux moving average)~~
- ~~Parabolic SAR~~
- ~~Williams %R~~
- ~~KST (know sure thing)~~
- ~~CCI (commodity channel index)~~
- ~~ROC (rate of change)~~
- ~~Momentum~~
- ~~Donchian Channel~~
- ~~Aroon Indicator / Aroon Oscillator~~
- ~~Stochastics~~
  - ~~Slow Stochastics~~
  - ~~Fast Stochastics~~
  - ~~Stochastic Momentum Index~~
- ~~MMA (modified moving average)~~
- ~~ZLEMA (zero lag exponential moving average)~~
- Hamming moving average
- VWMA (volume-weighted moving average)
- VWAP (volume-weighted average price)
- EVWMA (elastic, volume-weighted moving average)
- VMA (variable-length moving average)
- Chaikin Money Flow
- Ultimate Oscillator
- OBV (on-balance volume)
- Too many more to name...always happy to hear suggestions though!

# Examples
#### Randomly generated data:
![alt text](https://raw.githubusercontent.com/dysonance/Indicators.jl/master/examples/example1.png "Example 1")

#### Apple (AAPL) daily data from 2015:
![alt text](https://raw.githubusercontent.com/dysonance/Indicators.jl/master/examples/example2.png "Example 2")

#### Corn futures daily data
![alt text](https://raw.githubusercontent.com/dysonance/Indicators.jl/master/examples/example3.png "Example 3")


