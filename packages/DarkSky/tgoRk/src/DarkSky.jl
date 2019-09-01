VERSION >= v"1.0.0" && __precompile__()

module DarkSky

using ArgCheck
using HTTP
using JSON
using Dates

Optional{T} = Union{T, Nothing}
const SUPPORTED_LANGS = ["ar", "az", "be", "bg", "bs", "ca", "cs", "da", "de", "el", "en", "es",
                         "et", "fi", "fr", "hr", "hu", "id", "is", "it", "ja", "ka", "kw", "nb",
                         "nl", "pl", "pt", "ro", "ru", "sk", "sl", "sr", "sv", "tet", "tr", "uk",
                         "x-pig-latin", "zh", "zh-tw"]
const SUPPORTED_UNITS = ["auto", "ca", "uk2", "us", "si"]

struct DarkSkyResponse
    latitude::Float64
    longitude::Float64
    timezone::String
    offset::Optional{Int}
    currently::Optional{Dict}
    minutely::Optional{Dict}
    hourly::Optional{Dict}
    daily::Optional{Dict}
    alerts::Optional{Array}
    flags::Optional{Dict}
end
# DarkSkyResponse(x::Dict) = DarkSkyResponse((get.(x, String.(fieldnames(DarkSkyResponse)), nothing))...)
function DarkSkyResponse(x::Dict)
    DarkSkyResponse(
        get(x, "latitude", nothing),
        get(x, "longitude", nothing),
        get(x, "timezone", nothing),
        get(x, "offset", nothing),
        get(x, "currently", nothing),
        get(x, "minutely", nothing),
        get(x, "hourly", nothing),
        get(x, "daily", nothing),
        get(x, "alerts", nothing),
        get(x, "flags", nothing)
    )
end
Dict(x::DarkSkyResponse) = Dict(String(f) => getfield(x, f) for f in fieldnames(typeof(x)) if getfield(x, f) != nothing)
Base.convert(Dict, x::DarkSkyResponse) = Dict(x)

function Base.show(io::IO, x::DarkSkyResponse)
    print(io, (x.latitude, x.longitude))
end

for fieldname in fieldnames(DarkSkyResponse)
    fname = Symbol(fieldname)
    @eval begin
        ($fieldname)(x::DarkSkyResponse) = x.$fname
        export $fieldname
    end
end

function _get_json(url::String, out_type::String, verbose::Bool)
    response = HTTP.get(url)
    verbose ? info(response) : nothing
    if response.status == 200
        out = JSON.Parser.parse(String(response.body))
        if out_type == "DarkSkyResponse"
            return DarkSkyResponse(out)
        else
            return out
        end
    end
end

"""
    forecast(latitude::Float64, longitude::Float64; verbose::Bool=true, kwargs...)

Make a "Forecast Request", returns the current weather forecast for the next week.

# Arguments
- `latitude`: the latitude of a location (in decimal degrees). Positive is north, negative is south.
- `longitude`: the longitude of a location (in decimal degrees). Positive is east, negative is west.
- `verbose`: whether to display the HTTP request verbosely (optional).
- `exclude`: exclude some number of data blocks from the API response (optional).
- `extend`: when present, return hour-by-hour data for the next 168 hours, instead of the next 48 (optional).
- `lang`: return summary properties in the desired language (optional).
- `units`: return weather conditions in the requested units (optional).
"""
function forecast(latitude::Float64, longitude::Float64; verbose::Bool=false,
                  exclude::Optional{Array{String}}=nothing, extend::Optional{String}=nothing,
                  lang::String="en", units::String="us", out_type::String="DarkSkyResponse")
    @argcheck in(lang, SUPPORTED_LANGS)
    @argcheck in(units, SUPPORTED_UNITS)
    url = "https://api.darksky.net/forecast/$(ENV["DARKSKY_API_KEY"])/$latitude,$longitude?lang=$lang&units=$units"
    if !(exclude === nothing)
        url = "$url&exclude=$(join(exclude, ","))"
    end
    if !(extend === nothing)
        url = "$url&extend=$extend"
    end
    _get_json(url, out_type, verbose)
end

"""
    forecast(latitude::Float64, longitude::Float64, time::DateTime; verbose::Bool=true, kwargs...)

Make a "Time Machine Request", returns the observed or forecast weather conditions for a date in
the past or future.

# Arguments
- `latitude`: the latitude of a location (in decimal degrees). Positive is north, negative is south.
- `longitude`: the longitude of a location (in decimal degrees). Positive is east, negative is west.
- `time`: the timestamp for a Time Machine Request (optional).
- `verbose`: whether to display the HTTP request verbosely (optional).
- `exclude`: exclude some number of data blocks from the API response (optional).
- `lang`: return summary properties in the desired language (optional).
- `units`: return weather conditions in the requested units (optional).
"""
function forecast(latitude::Float64, longitude::Float64, time::DateTime; verbose::Bool=false,
                  exclude::Optional{Array{String}}=nothing, lang::String="en", units::String="us",
                  out_type::String="DarkSkyResponse")
    @argcheck in(lang, SUPPORTED_LANGS)
    @argcheck in(units, SUPPORTED_UNITS)
    url = "https://api.darksky.net/forecast/$(ENV["DARKSKY_API_KEY"])/$latitude,$longitude,$time?lang=$lang&units=$units"
    if !(exclude === nothing)
        url = "$url&exclude=$(join(exclude, ","))"
    end
    _get_json(url, out_type, verbose)
end

export forecast, DarkSkyResponse

end # module
