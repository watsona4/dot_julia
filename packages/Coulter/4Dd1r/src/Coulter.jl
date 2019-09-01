module Coulter

    __precompile__()

    using KernelDensity
    using Distributions
    using Gadfly
    using StatsBase
    using DataStructures
    import Base.-, Base.deepcopy
    using Dates: Second, DateTime

    export CoulterCounterRun, loadZ2, -, volume, diameter,
        extract_peak, extract_peak!, extract_peak_interval


    include("utils.jl")

    """
    A simplified representation of a coulter counter run
    """
    mutable struct CoulterCounterRun
        filename::String
        sample::String
        timepoint::DateTime
        reltime::Union{Second, Nothing}
        binlims::Vector{Float64}
        binvols::Vector{Float64}
        binheights::Vector{Number}
        """Whether the `binheights` is the raw count or total volume"""
        yvariable::Symbol
        data::Vector{Float64}
        livepeak::Union{Float64, Nothing}
        allpeaks::Vector{Float64}
        params::Dict{String, Any}
    end

    include("analysis.jl")

    # copy constructor
    deepcopy(a::CoulterCounterRun) = CoulterCounterRun([deepcopy(getfield(a, field)) for field in fieldnames(CoulterCounterRun)]...)

    """
    loadZ2(filename::String, sample::String)

    Loads `filename` and assigns it a sample, returns a
    `CoulterCounterRun` object
    """
    function loadZ2(filepath::String, sample::String; yvariable=:count)
        open(filepath) do s
            # split windows newlines if present
            filebody = replace(read(s, String), "\r\n"=>"\n")
            # extract start time and date from body
            datetime = match(r"^StartTime= \d*\s*(?<time>\d*:\d*:\d*)\s*(?<date>\d*\s\w{3}\s\d{4})$"m, filebody)
            timepoint = DateTime("$(datetime[:date]) $(datetime[:time])", "dd uuu yyy HH:MM:SS")

            params = Dict{String, Any}()
            params["Current"] = parse(Float64, match(r"^Cur=([+-]?[0-9]*[.]?[0-9]+)$"m, filebody)[1])
            params["Pre-Amp Gain"] = parse(Float64, match(r"^PAGn=([+-]?[0-9]*[.]?[0-9]+)$"m, filebody)[1])
            params["Volume metered"] = parse(Float64, match(r"^Vol=([+-]?[0-9]*[.]?[0-9]+)$"m, filebody)[1])

            # extract data
            matcheddata = match(r"^\[#Bindiam\]\n(?<binvols>.*?)\n^\[Binunits\].*?\[#Binheight\]\n(?<binheight>.*?)\n^\[end\]"sm, filebody)
            binlims = [volume(parse(Float64, x)) for x in split(matcheddata[:binvols], "\n ")]
            # the Coulter software takes the mean the upper and lower limits to
            # compute the volume of everything that falls in the bin
            binvols = [(binlims[i] + binlims[i+1])/2 for i in 1:length(binlims)-1]
            binheights = Int[parse(Int, x) for x in split(matcheddata[:binheight], "\n ")]
            pop!(binheights) # remove the last extraneous value

            # unbin data, i.e. the inverse of the hist function
            data = repvec(binvols, binheights)

            if yvariable == :volume
                binheights = binvols .* binheights
            end

            CoulterCounterRun(basename(filepath), sample, timepoint, nothing,
                              binlims, binvols, binheights, yvariable, data,
                              nothing, Float64[], params)
        end
    end

    loadZ2(filepath::String) = loadZ2(filepath, "N/A")

    -(a::CoulterCounterRun, b::CoulterCounterRun) = a.timepoint - b.timepoint
    -(a::CoulterCounterRun, b::DateTime) = a.timepoint - b
end
