# Google Maps

Unofficial Julia wrapper for the Google Maps API.

[![Build Status](https://travis-ci.org/ellisvalentiner/GoogleMaps.jl.svg?branch=master)](https://travis-ci.org/ellisvalentiner/GoogleMaps.jl)

[![Coverage Status](https://coveralls.io/repos/ellisvalentiner/GoogleMaps.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/ellisvalentiner/GoogleMaps.jl?branch=master)

[![codecov.io](http://codecov.io/github/ellisvalentiner/GoogleMaps.jl/coverage.svg?branch=master)](http://codecov.io/github/ellisvalentiner/GoogleMaps.jl?branch=master)

## Overview

This package is an unofficial wrapper for the Google Maps API.

The Google Maps API requires an API key. See the [Google Maps API Documentation](https://developers.google.com/maps/documentation/) to request one.

## Installation

```julia
# GoogleMaps.jl is not currently registered as an official package
# Please install the development version from GitHub:
]add git://github.com/ellisvalentiner/GoogleMaps.jl.git
```

GoogleMaps.jl expects your API key to be stored as an environment variable named `GOOGLE_MAPS_KEY`.

## Usage

```julia
using GoogleMaps

geocode("1600+Amphitheatre+Parkway,+Mountain+View,+CA")
timezone((37.4226128, -122.0854158))
```
