module Pitchjx

export
    pitchjx

using EzXML
using DataFrames
using Dates

include(joinpath(dirname(@__FILE__), "extractor.jl"))

"""
Scrape MLBAM pitchfx data.

# How to use

`pitchjx("2018-10-20")`
"""
function pitchjx(start, fin=start)
    @info "Initialize: Start"
    result = DataFrame()
    date = Date(start)
    findate = Date(fin)
    @info "Initialize: Finish!"
    @info "Extract dataset: Start"
    while date <= findate
        df = extract(date)
        if size(result) == (0, 0)
            result = df
        else
            result = vcat(result, df)
        end
        date += Dates.Day(1)
    end
    @info "Extract dataset: Finish!"
    return result
end

end
