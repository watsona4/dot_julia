module GoogleMaps

using ArgCheck
using HTTP
using JSON
using Dates

include("geocoding.jl")
export geocode

include("timezone.jl")
export timezone

end
