struct IfsSeries <: IMFSeries
    database::AbstractString
    area::AbstractString
    indicator::AbstractString
    description::AbstractString
    frequency::AbstractString
    startyear::Int
    endyear::Int
    time_format::AbstractString
    unit_mult::AbstractString
    series::DataFrame
end

IfsSeries(area, indicator, frequency, startyear, endyear, time_format, unit_mult,
    series) = IfsSeries("IFS", area, indicator, "", frequency, startyear,
    endyear, time_format, unit_mult, series)

function Base.show(io::IO, imf::IfsSeries)
    println(io, "IMF Data Series")
    println(io, "Database: IFS")
    println(io, "Area: $(imf.area)")
    println(io, "Indicator: $(imf.indicator)")
    println(io, "Description: $(imf.description)")
    println(io, "Frequency: $(imf.frequency)")
    println(io, "Time Period: $(imf.startyear) to $(imf.endyear)")
    println(io, "Data: $(size(imf.series, 1)) x $(size(imf.series, 2)) DataFrame")
end

struct IfsNotDefined <:IMFSeries
    area::AbstractString
    indicator::AbstractString
    startyear::Int
    endyear::Int
end

function Base.show(io::IO, imf::IfsNotDefined)
    println(io, "IMF Data Series")
    println(io, "Database: IFS")
    println(io, "Area: $(imf.area)")
    println(io, "Indicator: $(imf.indicator)")
    println(io, "Time Period: $(imf.startyear) to $(imf.endyear)")
    println(io, "Note: Indicator not defined for the given area or time period")
end

struct IfsNoData <: IMFSeries
    database::AbstractString
    area::AbstractString
    indicator::AbstractString
    frequency::AbstractString
    startyear::Int
    endyear::Int
end

IfsNoData(area, indicator, frequency, startyear, endyear) = IfsNoData("IFS", area, indicator,
    frequency, startyear, endyear)

function Base.show(io::IO, imf::IfsNoData)
    println(io, "IMF Data Series")
    println(io, "Database: IFS")
    println(io, "Area: $(imf.area)")
    println(io, "Indicator: $(imf.indicator)")
    println(io, "Frequency: $(imf.frequency)")
    println(io, "Time Period: $(imf.startyear) to $(imf.endyear)")
    println(io, "Note: Data not available for the given frequency or time period")
end

"""
    get_ifs_data(area::String, indicator::String, frequency::String, startyear::Int, endyear::Int)

Retrieve data for a single area-indicator pair from IFS dataset
"""
function get_ifs_data(area::String, indicator::String, frequency::String, startyear::Int, endyear::Int)
    valid_freq = ["M", "Q", "A"]
    if frequency ∉ valid_freq
        error("Frequency must be one of ", valid_freq)
    end

    if startyear > endyear
        error("startyear must be less than endyear")
    end

    method  = "CompactData"
    dataset = "IFS"

    full_url  = join([IMFData.API_URL, method, dataset], "/")
    params    = join([frequency, area, indicator], ".")
    daterange = string("startPeriod=", startyear, "&endPeriod=", endyear)
    query     = join([full_url, params, daterange], "/", "?")

    response = get_series(query, 10)
    response_body = String(response.body)
    response_json = JSON.parse(response_body)
    dataseries = response_json["CompactData"]["DataSet"]

    if haskey(dataseries, "Series")
        out = parse_series_dict(dataseries["Series"], frequency, startyear, endyear)
    else
        out = IfsNotDefined(area, indicator, startyear, endyear)
    end

    return out
end

function get_ifs_data(area::Array{String}, indicator::String, frequency::String, startyear::Int, endyear::Int)
    out = Array{IMFSeries, 1}()
    for a in area
        push!(out, get_ifs_data(a, indicator, frequency, startyear, endyear))
    end
    return out
end

function get_ifs_data(area::String, indicator::Array{String}, frequency::String, startyear::Int, endyear::Int)
    out = Array{IMFSeries, 1}()
    for i in indicator
        push!(out, get_ifs_data(area, i, frequency, startyear, endyear))
    end
    return out
end

function get_ifs_data(area::Array{String}, indicator::Array{String}, frequency::String, startyear::Int, endyear::Int)
    out = Array{IMFSeries, 1}()
    for a in area
        for i in indicator
            push!(out, get_ifs_data(a, i, frequency, startyear, endyear))
        end
    end
    return out
end

function get_series(query::String, retries::Int)
    if retries == 0
        error("Query $(query) failed.")
    else
        response = HTTP.get(query)
        content_type = Dict(response.headers)["Content-Type"]
        if occursin("json", content_type)
            return response
        else
            return get_series(query, retries-1)
        end
    end
end

function parse_series_dict(d::Dict, frequency, startyear, endyear)
    area      = d["@REF_AREA"]
    indicator = d["@INDICATOR"]
    time_format = d["@TIME_FORMAT"]
    unit_mult = d["@UNIT_MULT"]

    if haskey(d, "Obs")
        series = extract_observations(d["Obs"], frequency)
        actual_startyear = Dates.year(series[:date][1])
        actual_endyear   = Dates.year(series[:date][end])
        out = IfsSeries(area, indicator, frequency, actual_startyear, actual_endyear,
            time_format, unit_mult, series)
    else
        out = IfsNoData(area, indicator, frequency, startyear, endyear)
    end
end

function extract_observations(obs::Dict, frequency)
    series = DataFrame(date = Date[], value = Float64[])
    observation = single_observation(obs, frequency)
    push!(series, observation)
    return series
end

function extract_observations(obs::Vector, frequency)
    series = DataFrame(date = Date[], value = Float64[])
    for od in obs
        observation = single_observation(od, frequency)
        push!(series, observation)
    end
    return series
end

function single_observation(od::Dict, frequency)
    time_period = od["@TIME_PERIOD"]
    year = parse(Int, time_period[1:4])
    ## Monthly data
    if frequency == "M"
        month = parse(Int, time_period[6:7])
    ## Quarterly data
    elseif frequency == "Q"
    # if ismatch(r"Q", time_period)
        quarter = parse(Int, time_period[end])
        month = quarter*3
    ## Annual data
    elseif frequency == "A"
        month = 12
    else
        error("Invalid frequency")
    end
    date = Date(year, month, 1)
    # Get the observation value
    value = parse(Float64, od["@OBS_VALUE"])
    return (date, value)
end
