module DeIdentification

export deidentify, ProjectConfig, DeIdDicts, build_config, build_config_from_csv

import YAML
import Glob
import JSON
import Tables
import CSV
import Dates
import SHA: bytes2hex, sha256
import Random: shuffle, randstring, seed!, make_seed
import Memento
import DataStructures: OrderedDict
import REPL
using REPL.TerminalMenus

include("config_builder.jl")
include("de_identify.jl")
include("exporting.jl")
include("utils.jl")

"""
    deid_file!(dicts, file_config, project_config, logger)

Reads raw file and deidentifies per file configuration and project configurationg.
Writes the deidentified data to a CSV file and updates the global dictionaries
tracking identifier mappings.
"""
function deid_file!(dicts::DeIdDicts, fc::FileConfig, pc::ProjectConfig, logger)

    # Initiate new file
    infile = CSV.File(fc.filename, dateformat = pc.dateformat)
    outfile = joinpath(pc.outdir, "deid_" * fc.name * "_" * getcurrentdate() * ".csv")

    ncol = length(infile.names)
    lastcol = infile.names[end]

    new_names = Vector{Symbol}()
    new_types = Vector{Type}()
    pk = false
    pcol = pc.primary_id

    Memento.info(logger, "$(Dates.now()) Renaming file columns")
    for i = 1:ncol
        n = infile.names[i]
        t = infile.types[i]

        if haskey(fc.rename_cols, n)
            push!(new_names, fc.rename_cols[n])
            push!(new_types, t)

            if fc.rename_cols[n] == pc.primary_id
                pk = true
                pcol = n
            end
        elseif get(fc.colmap, n, Missing) == Drop
            continue
        else
            push!(new_names, n)
            push!(new_types, t)
        end

        if n == pc.primary_id
            pk = true
        end
    end

    Memento.info(logger, "$(Dates.now()) Checking for primary column")
    @assert pk==true "Primary ID must be present in file"

    open(outfile, "w") do io
        # write header to file
        CSV.printheader(
            io, [string(n) for n in new_names], ",", '"', '"', '"', '\n')

        # Process each row
        for row in infile

            val = getoutput(dicts, Hash, getproperty(row, pcol), 0)
            pid = setrid(val, dicts)

            for col in infile.names
                colname = get(fc.rename_cols, col, col)

                action = get(fc.colmap, colname, Missing) ::Type
                # drop cols
                action == Drop && continue

                VAL = getproperty(row, col)

                # apply pre-processing transform
                if haskey(fc.preprocess, colname) && !ismissing(VAL)
                    transform = fc.preprocess[colname]
                    transform = replace(transform, "VAL" => "\"$VAL\"")
                    expr = Meta.parse(transform)
                    VAL = Core.eval(@__MODULE__, expr)
                end

                VAL = getoutput(dicts, action, VAL, pid)

                if col == pcol
                    VAL = pid
                end

                # apply post-processing transform
                if haskey(fc.postprocess, colname) && !ismissing(VAL)
                    transform = fc.postprocess[colname]
                    transform = replace(transform, "VAL" => "\"$VAL\"")
                    expr = Meta.parse(transform)
                    VAL = Core.eval(@__MODULE__, expr)
                end

                if eltype(VAL) <: String
                    VAL = replace(VAL, "\"" => "\\\"")
                end

                write(io, "\"$VAL\"")
                if lastcol == col
                    write(io, '\n')
                else
                    write(io, ",")
                end
            end
        end

    end

    return nothing
end



"""
    deidentify(cfg::ProjectConfig)
This is the constructor for the `DeIdentified` struct. We use this type to store
arrays of `DeIdDataFrame` variables, while also keeping a common `salt_dict` and
`dateshift_dict` between `DeIdDataFrame`s. The `salt_dict` allows us to track
what salt was used on what cleartext. This is only necessary in the case of doing
re-identification. The `id_dict` argument is a dictionary containing the hash
digest of the original primary ID to our new research IDs.
"""
function deidentify(cfg::ProjectConfig)
    num_files = length(cfg.file_configs)
    dicts = DeIdDicts(cfg.maxdays, cfg.shiftyears)

    if !isdir(cfg.outdir)
        # mkpath also creates any intermediate paths
        mkpath(cfg.outdir)
    end

    logdir = dirname(cfg.logfile)
    if !isdir(logdir)
        mkpath(logdir)
    end

    # Set up our top-level logger
    logger = Memento.getlogger("deidentify")
    logfile_roller = Memento.FileRoller(cfg.logfile)
    push!(logger, Memento.DefaultHandler(logfile_roller))

    Memento.info(logger, "$(Dates.now()) Logging session for project $(cfg.name)")

    Memento.info(logger, "$(Dates.now()) Setting seed for project $(cfg.name)")
    seed!(cfg.seed)


    for (i, fc) in enumerate(cfg.file_configs)
        Memento.info(logger, "$(Dates.now()) ====================== Processing $(fc.name) ======================")

        Memento.info(logger, "$(Dates.now()) Reading data from $(fc.filename)")
        deid_file!(dicts, fc, cfg, logger)

    end

    write_dicts(dicts, logger, cfg.outdir)

    return dicts
end

"""
    deidentify(config_path)

Run entire pipeline: Processes configuration YAML file, de-identifies the data,
and writes the data to disk.  Returns the dictionaries containing the mappings.
"""
function deidentify(cfg_file::String)
    proj_config = ProjectConfig(cfg_file)
    return deidentify(proj_config)
end


end # module
