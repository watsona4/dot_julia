using EchoviewEvr

using Test

filename = joinpath(dirname(@__FILE__),
                  "data/WCBjr280_1_1_regions.evr")

_regions = collect(regions(filename))

@test length(_regions) == 68
@test _regions[1].classification == "krills"
@test _regions[1].regiontype == "1"

_polygons = polygons(_regions)
@test length(_polygons) == 68

_polygons = polygons(filename)
@test length(_polygons) == 68
