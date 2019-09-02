"""
    function mc_run_id(fname::AbstractString)

Generate a (unique) run ID for a given filename.
"""
function mc_run_id(fname::AbstractString)
    bname = basename(fname)
    if contains(bname, "_muatm")
        s = split(split(bname, "_muatm")[2], ".")[1]
        energy_cut, run = split(s, "T")
        return parse(Int, energy_cut) * 10000 + parse(Int, run)
    end
    if contains(bname, "_numuCC_")
        run = split(split(bname, "_numuCC_")[2], ".")[1]
        return parse(Int, run)
    end
    error("Don't know how to generate a proper run ID for '$bname'.")
end


"""
    function make_mc_time_converter(event_info::Union{MCEventInfo,DAQEventInfo})

Returns a function which converts MC time to JTE time.
"""
function make_mc_time_converter(event_info::Union{MCEventInfo,DAQEventInfo})
    function time_converter(time)
        return time - (event_info.timestamp * 1e9 + event_info.nanoseconds) + event_info.mc_time
    end
    return time_converter
end


"""
    function cherenkov_origin(pos, t::Track)

Calculate the origin of the Cherenkov photon on a track.
"""
function cherenkov_origin(pos, t::Track)
    θ = acos(1/N_SEAWATER)
    P = project(pos, t) 
    dir = -normalize(t.dir)
    track_distance = pld3(pos, t.pos, t.dir)
    distance = track_distance / tan(θ)
    Position(P + distance*dir)
end
