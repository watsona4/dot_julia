# BritishNationalGrid

[![Build Status](https://img.shields.io/travis/anowacki/BritishNationalGrid.jl.svg?style=flat-square&label=linux)](https://travis-ci.org/anowacki/BritishNationalGrid.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/sl5syqbammvm2ck9?svg=true)](https://ci.appveyor.com/project/AndyNowacki/britishnationalgrid)
[![Coverage Status](https://coveralls.io/repos/github/anowacki/BritishNationalGrid.jl/badge.svg?branch=master)](https://coveralls.io/github/anowacki/BritishNationalGrid.jl?branch=master)

## Convert between WGS84 coordinates and British National Grid references

`BritishNationalGrid` provides the type `BNGPoint` to convert between
longitude-latitude and grid references in the [British National Grid system](https://en.wikipedia.org/wiki/Ordnance_Survey_National_Grid).
It assumes your points are geodetic longitude and latitude in decimal
degrees using the WGS84 ellipsoid.

This package is reliable to within a metre or so.  Advanced users needing
greater accuracy will probably already know how to convert between different
systems, but any additions to the package that remain easy to use will
be welcome.

## Install
```julia
julia> import Pkg

julia> Pkg.add("BritishNationalGrid")
```

## Use
Construct points in the grid using `BNGPoint`.

```julia
julia> using BritishNationalGrid

julia> p1 = BNGPoint(42513, 100231) # Full grid reference
BNGPoint{Int64}(42513, 100231)

julia> lonlat(p1) # Convert to longitude-latitude (°)
(-7.063648859478239, 50.69155306935914)

julia> p2 = BNGPoint(lon=0.32, lat=51.0) # Construct point from lon-lat
BNGPoint{Float64}(562885.4557430055, 124851.2191743746)

julia> p3 = BNGPoint(00123, 51422, "TA") # Construct from 100 km square name
BNGPoint{Int64}(500123, 451422)
```

Get a formatted grid reference:

```julia
julia> gridref(p1, 10) # 10-figure grid reference
"04251 10023"

julia> gridref(p2, 6, true) # 6-figure reference within the 100 km square TQ
"TQ 628 248"
```

Find the 100 km square in which a point lies:

```julia
julia> square(p3)
"TA"
```

## Todo
- Tie the BNGPoint type into [Geodesy.jl](https://github.com/JuliaGeo/Geodesy.jl).

## Other ways to convert to the British National Grid

- Use the Ordnance Survey's [online converter](https://www.ordnancesurvey.co.uk/gps/transformation/).  This also
  includes links to the OS's Pascal programs to do coordinate transforms.
- Use the British Geological Survey's [online converter](http://www.bgs.ac.uk/data/webservices/convertform.cfm), which also
  assumes WGS84 longitude and latitude.
