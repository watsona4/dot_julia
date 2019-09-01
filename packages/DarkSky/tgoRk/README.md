# DarkSky.jl

A Julia wrapper for the Dark Sky weather data API.

[![Build Status](https://travis-ci.org/ellisvalentiner/DarkSky.jl.svg?branch=master)](https://travis-ci.org/ellisvalentiner/DarkSky.jl)

[![Coverage Status](https://coveralls.io/repos/github/ellisvalentiner/DarkSky.jl/badge.svg?branch=master)](https://coveralls.io/github/ellisvalentiner/DarkSky.jl?branch=master) [![codecov](https://codecov.io/gh/ellisvalentiner/DarkSky.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/ellisvalentiner/DarkSky.jl)

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://ellisvalentiner.github.io/DarkSky.jl/stable) [![](https://img.shields.io/badge/docs-latest-blue.svg)](https://ellisvalentiner.github.io/DarkSky.jl/latest)

## Overview

This package is a wrapper for the Dark Sky API.

The Dark Sky API requires an API key. See the [Dark Sky Developer Documentation](https://darksky.net/dev/docs) to request one.

## Installation

```julia
# Install the latest stable version:
Pkg.install("DarkSky")
 Or the the development version from GitHub:
Pkg.clone("git://github.com/ellisvalentiner/DarkSky.jl.git")
```

DarkSky.jl expects your API key to be stored as an environment variable named `DARKSKY_API_KEY`.

## Usage

The basic usage is to request the current weather forecast (a [Forecast Request](https://darksky.net/dev/docs#forecast-request)) or the observed or forecast weather conditions for a datetime in the past or future (a [Time Machine Request](https://darksky.net/dev/docs#time-machine-request)).

```julia
using DarkSky
# Make a "Forecast Request", returns the current weather forecast for the next week.
response = forecast(42.3601, -71.0589);
# Make a "Time Machine Request", returns the observed or forecast weather conditions for a date in
# the past or future.
response = forecast(42.3601, -71.0589, DateTime(2018, 3, 7, 14, 19, 57));
```

The Dark Sky response contains the following properties (and can be accessed by functions with the same name):

* `latitude` - The requested latitude.
* `longitude` - The requested longitude.
* `timezone` - The IANA timezone name for the requested location.
* `currently` - A data point containing the current weather conditions at the requested location. (optional)
* `minutely` - A data block containing the weather conditions minute-by-minute for the next hour. (optional)
* `hourly` - A data block containing the weather conditions hour-by-hour for the next two days. (optional)
* `daily` - A data block containing the weather conditions day-by-day for the next week. (optional)
* `alerts` - An alerts array, which, if present, contains any severe weather alerts pertinent to the requested location. (optional)
* `flags` - A flags object containing miscellaneous metadata about the request. (optional)

```julia
# Extract the requested latitude
latitude(response)
# Extract the "daily" data block
daily(response)
# Extract the "alerts" data block
alerts(response)
```

Note that optional properties may not contain data (e.g. there may be no alerts).

## Contributing

See the [CONTRIBUTING](https://github.com/ellisvalentiner/DarkSky.jl/blob/master/CONTRIBUTING) file.

## Conduct

We adhere to the [Julia community standards](http://julialang.org/community/standards/).

## License

The code is available under the [MIT License](https://github.com/ellisvalentiner/DarkSky.jl/blob/master/LICENSE).
