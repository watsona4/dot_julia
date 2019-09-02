module NIRX

using DelimitedFiles, CSV

export read_NIRX

function read_NIRX(directory::String)
    @assert isdir(directory) string("Directory does not exist:", directory)
    @info "Loading directory $(directory)"

    # Check required files
    directory_files = readdir(directory)
    required_file_types = ["evt", "hdr", "inf", "set", "tpl", "wl1", "wl2", "txt", "mat"]
    for required_file_type in required_file_types
        matching_files = [endswith(filename, required_file_type) for filename in directory_files]
        @assert sum(matching_files) == 1 "Incorrect number of *.$(required_file_type) file. N = $(sum(matching_files))"
    end

    # Determine base filename
    file_basename = directory_files[[endswith(filename, "wl1") for filename in directory_files]][1][1:end-4]
    @debug "Base file name is $file_basename"

    triggers = read_event_file(string(directory, "/", file_basename, ".evt"))
    header_info, header_triggers = read_header_file(string(directory, "/", file_basename, ".hdr"))
    info  = read_information_file(string(directory, "/", file_basename, ".inf"))
    wl1  = read_wavelength_file(string(directory, "/", file_basename, ".wl1"))
    wl2  = read_wavelength_file(string(directory, "/", file_basename, ".wl2"))
    config  = read_config_file(string(directory, "/", file_basename, "_config.txt"))

    @assert triggers[:, 1] == header_triggers[:, 3] "Header and event files do not match"
    @assert triggers[:, 2] == header_triggers[:, 2] "Header and event files do not match"

    return triggers, header_info, info, wl1, wl2, config
end


function read_event_file(filename::String)
    # Read event file
    event_file_raw_data = readdlm(filename, Float64)
    event_times = event_file_raw_data[:, 1]
    event_values = event_file_raw_data[:, 2:end]
    event_values = [round(Int, v) for v in event_values]
    #TODO find a cleaner way to convert arrays from binary to integer
    event_values_out = Array{Int}(undef, size(event_file_raw_data, 1), 1)
    for idx = 1:size(event_file_raw_data, 1)
        s = string("0b")
        for val_idx = size(event_values, 2):-1:1
            s = string(s, string(event_values[idx, val_idx]))
        end
        event_values_out[idx] = round(Int, Meta.parse(s))
    end
    event_values_out = vec(event_values_out)
    triggers = [event_times event_values_out]
    @debug "Imported $(size(event_file_raw_data, 1)) events"

    return triggers
end


function read_header_file(filename::String)

    f = open(filename)
    HDR = Dict()
    line_out = readline(f)
    while !occursin("GainSettings", line_out)
        line_out = readline(f)
        if !isempty(line_out) & occursin("=", line_out)
            split_string = split(line_out, "=")
            split_string[2] = replace(split_string[2], "\"" => "")
            HDR[split_string[1]] = split_string[2]
        end
    end

    # Read gains
    # TODO read gains
    while !occursin("Markers", line_out)
        line_out = readline(f)
    end

    # Triggers
    line_out = readline(f)
    line_out = readline(f)
    header_triggers_time = Float64[]
    header_triggers_value = Int64[]
    header_triggers_sample = Int64[]
    while !occursin("#", line_out)
        split_string = split(line_out, "\t")
        append!(header_triggers_time, parse(Float64, split_string[1]))
        append!(header_triggers_value, parse(Int64, split_string[2]))
        append!(header_triggers_sample, parse(Int64, split_string[3]))
        line_out = readline(f)
    end
    triggers = [header_triggers_time header_triggers_value header_triggers_sample]

    # SD Pairs
    line_out = readline(f)
    line_out = readline(f)
    line_out = readline(f)
    header_SD_source = Int64[]
    header_SD_detector = Int64[]
    header_SD_index = Int64[]
    regexp = r"(\d+)-(\d+):(\d+)"
    m = eachmatch(regexp, line_out)
    for matches in m
        append!(header_SD_source, parse(Int64, matches[1]))
        append!(header_SD_detector, parse(Int64, matches[2]))
        append!(header_SD_index, parse(Int64, matches[3]))
    end

    line_out = readline(f)
    SD_mask = Array{Int64}(undef, maximum(header_SD_source), maximum(header_SD_detector))
    regexp = r"(\d+)"
    for source = 1:size(SD_mask, 1)
        line_out = readline(f)
        split_string = split(line_out, "\t")
        SD_mask[source, :] = [parse(Int64, s) for s in split_string]
    end
    header_SD_mask = Vector{Int64}(undef, length(header_SD_detector))
    for pair_idx in 1:length(header_SD_detector)
        header_SD_mask[pair_idx] = SD_mask[header_SD_source[pair_idx], header_SD_detector[pair_idx]]
    end

    HDR["SourceDetectorMask"] = [header_SD_source header_SD_detector header_SD_index header_SD_mask]
    # SD is source, detector, index, mask


    @debug "Imported header data from file $filename"
    return HDR, triggers
end


function read_information_file(filename::String)

    f = open(filename)
    INF = Dict()
    line_out = readline(f)
    while !eof(f)
        line_out = readline(f)
        if !isempty(line_out) & occursin("=", line_out)
            split_string = split(line_out, "=")
            split_string[2] = replace(split_string[2], "\"" => "")
	    INF[split_string[1]] = string(split_string[2])
        end
    end

    # Fix types for things that arent strings
    if ~isempty(INF["Age"])
        INF["Age"] = parse(Float64, INF["Age"])
    end

    @debug "Imported information data from file $filename"
    return INF
end

function read_wavelength_file(filename::String)
    dataframe = CSV.read(filename, delim=' ', header=0)
    data = convert(Matrix, dataframe)
    @debug "Imported wavelength data from file $filename"
    return data
end


function read_config_file(filename::String)

    f = open(filename)
    CFG = Dict()
    while !eof(f)
        line_out = readline(f)
        if !isempty(line_out) & occursin("=", line_out)
            split_string = split(line_out, "=")
            split_string[2] = replace(split_string[2], "\"" => "")
            CFG[split_string[1]] = split_string[2]
        end
    end
    @debug "Imported config data from file $filename"
    return CFG
end


end
