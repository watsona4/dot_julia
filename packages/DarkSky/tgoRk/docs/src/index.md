# DarkSky.jl

A Julia wrapper for the Dark Sky weather data API.

[![Build Status](https://travis-ci.org/ellisvalentiner/DarkSky.jl.svg?branch=master)](https://travis-ci.org/ellisvalentiner/DarkSky.jl)

[![coveralls](https://coveralls.io/repos/ellisvalentiner/DarkSky.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/ellisvalentiner/DarkSky.jl?branch=master) [![codecov](https://codecov.io/gh/ellisvalentiner/DarkSky.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/ellisvalentiner/DarkSky.jl)

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://ellisvalentiner.github.io/DarkSky.jl/stable) [![](https://img.shields.io/badge/docs-latest-blue.svg)](https://ellisvalentiner.github.io/DarkSky.jl/latest)

## Overview

This package is a wrapper for the Dark Sky API.

The Dark Sky API requires an API key. See the [Dark Sky Developer Documentation](https://darksky.net/dev/docs) to request one.

## Installation

```julia
# DarkSky.jl is not currently registered as an official package
# Please install the development version from GitHub:
Pkg.clone("git://github.com:ellisvalentiner/DarkSky.jl.git")
```

DarkSky.jl expects your API key to be stored as an environment variable named `DARKSKY_API_KEY`.

## Usage

```julia
using DarkSky
# Make a "Forecast Request", returns the current weather forecast for the next week.
forecast(42.3601, -71.0589)
# Make a "Time Machine Request", returns the observed or forecast weather conditions for a date in
# the past or future.
forecast(42.3601, -71.0589, DateTime(2018, 3, 7, 14, 19, 57))
```

## Contributing

See the [CONTRIBUTING](https://github.com/ellisvalentiner/DarkSky.jl/blob/master/CONTRIBUTING) file.

## Conduct

We adhere to the [Julia community standards](http://julialang.org/community/standards/).

## License

The code is available under the [MIT License](https://github.com/ellisvalentiner/DarkSky.jl/blob/master/LICENSE).
