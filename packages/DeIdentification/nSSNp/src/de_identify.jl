# de_identify.jl

# types of column deidentification
abstract type Hash end
abstract type Salt end
abstract type DateShift end
abstract type Drop end

# utility function to get column names from YAML
function getcols(ds, col::String)
    map(Symbol, get(ds, col, Array{String,1}()))
end

"""
    FileConfig(name, filename, colmap, rename_cols)

Structure containing configuration information for each datset in the configuration
YAML file.  The colmap contains mapping of column names to their deidentification
action (e.g. hash, salt, drop).
"""
struct FileConfig
    name::String
    filename::String
    colmap::Dict{Symbol, Type}
    rename_cols::Dict{Symbol,Symbol}
    preprocess::Dict{Symbol, String}
    postprocess::Dict{Symbol, String}
end


struct ProjectConfig
    name::String
    logfile::String
    outdir::String
    seed::Int
    file_configs::Array{FileConfig,1}
    maxdays::Int
    shiftyears::Int
    primary_id::Symbol
    dateformat::String
end

"""
    ProjectConfig(config_file::String)

Structure containing configuration information for project level information in the configuration
YAML file.  This includes an array containing the FileConfig structures for dataset
level information.
"""
function ProjectConfig(cfg_file::String)
    cfg = YAML.load(open(cfg_file))
    logfile = joinpath(cfg["log_path"], cfg["project"]*".log")
    num_file = length(cfg["datasets"])
    outdir = cfg["output_path"]
    pk = Symbol(cfg["primary_id"])
    dateformat = get(cfg, "date_format", "y-m-dTH:M:S.s")

    seed = get(cfg, "project_seed", _ -> make_seed()[1])
    maxdays = get(cfg, "max_dateshift_days", 30)
    shiftyears = get(cfg, "dateshift_years", 0)

    # initialize File Configs for data sets
    file_configs = Array{FileConfig,1}(undef, 0)

    # populate File Configs
    for (i, ds) in enumerate(cfg["datasets"])
        
        name = ds["name"]
        rename_dict = Dict{Symbol,Symbol}()
        for pair in get(ds, "rename_cols", [])
            rename_dict[Symbol(pair["in"])] = Symbol(pair["out"])
        end

        preprocess_dict = Dict{Symbol,String}()
        for pair in get(ds, "preprocess_cols", [])
            preprocess_dict[Symbol(pair["col"])] = pair["transform"]
        end

        postprocess_dict = Dict{Symbol,String}()
        for pair in get(ds, "postprocess_cols", [])
            postprocess_dict[Symbol(pair["col"])] = pair["transform"]
        end

        col_map = Dict{Symbol, Type}()
        [col_map[col] = Hash       for col in getcols(ds, "hash_cols")]
        [col_map[col] = Salt       for col in getcols(ds, "salt_cols")]
        [col_map[col] = DateShift  for col in getcols(ds, "dateshift_cols")]
        [col_map[col] = Drop       for col in getcols(ds, "drop_cols")]

        for (j, f) in enumerate(Glob.glob(ds["filename"]))
            filename = f
            file_config = FileConfig(name, filename, col_map, rename_dict, preprocess_dict, postprocess_dict)
            push!(file_configs, file_config)
        end
    end

    return ProjectConfig(cfg["project"], logfile, outdir, seed, file_configs, maxdays, shiftyears, pk, dateformat)
end


struct DeIdDicts
    id::Dict{String, Int}
    salt::Dict{Int, String}
    dateshift::Dict{Int, Int}
    maxdays::Int
    shiftyears::Int
end

"""
    DeIdDicts(maxdays)

Structure containing dictionaries for project level mappings
- Primary ID -> Research ID
- Research ID -> DateShift number of days
- Research ID -> Salt value
"""
DeIdDicts(maxdays, shiftyears) = DeIdDicts(Dict{String, Int}(), Dict{Int, String}(), Dict{Int, Int}(), maxdays, shiftyears)


"""
    hash_salt_val!(dicts, val, pid)

Salt and hash fields containing unique identifiers. Hashing is done in place
using SHA256 and a 64-bit salt. Of note is that missing values are left missing.
"""
function hash_salt_val!(dicts::DeIdDicts, val, pid::Int)

    ismissing(val) && return val

    if haskey(dicts.salt, pid)
        salt = dicts.salt[pid]
    else
        salt = randstring(16)
        dicts.salt[pid] = salt
    end

    return bytes2hex(sha256(string(val, salt)))

end

"""
    dateshift_val!(dicts, val, pid)

Dateshift fields containing dates. Dates are shifted by a maximum number of days
specified in the project config.  All of the dates for the same primary key are
shifted the same number of days. Of note is that missing values are left missing.
"""
function dateshift_val!(dicts::DeIdDicts, val::Union{Dates.Date, Dates.DateTime, Missing}, pid::Int)

    ismissing(val) && return val

    if haskey(dicts.dateshift, pid)
        n_days = dicts.dateshift[pid]
    else
        max_days = dicts.maxdays
        n_days = rand(-max_days:max_days)
        dicts.dateshift[pid] = n_days
    end

    return val + Dates.Day(n_days) + Dates.Year(dicts.shiftyears)

end

"""
    setrid(val, dicts)

Set the value passed (a hex string) to a human readable integer.  It generates
a new ID if the value hasn't been seen before, otherwise the existing ID is used.
"""
function setrid(val, dicts::DeIdDicts)
    @assert !ismissing(val) "Primary ID cannot be missing"

    if haskey(dicts.id, val)
        val = dicts.id[val]
    else
        new_id = 1 + length(dicts.id)
        dicts.id[val] = new_id
        val = new_id
    end

    return val
end


# Series of getoutput functions for each type of action
function getoutput(dicts::DeIdDicts, ::Type{Missing}, val, pid::Int)
    return val
end

function getoutput(dicts::DeIdDicts, ::Type{Drop}, val, pid::Int)
    return nothing
end

function getoutput(dicts::DeIdDicts, ::Type{Hash}, val, pid::Int)
    return bytes2hex(sha256(string(val)))
end

function getoutput(dicts::DeIdDicts, ::Type{Salt}, val, pid::Int)
    return hash_salt_val!(dicts, val, pid)
end

function getoutput(dicts::DeIdDicts, ::Type{DateShift}, val, pid::Int)
    return dateshift_val!(dicts, val, pid)
end
