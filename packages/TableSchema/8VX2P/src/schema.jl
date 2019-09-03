"""
Table Schema main type
https://github.com/frictionlessdata/tableschema-jl#schema
"""
mutable struct Schema
    errors::Array{SchemaError}
    descriptor::Dict
    primary_key::Array{String}
    foreign_keys::Array{Dict}
    missing_values::Array{String}
    fields::Array{Field}

    function Schema(d::Dict, strict::Bool=false)
        fls = haskey(d, "fields") ? [ Field(f) for f in d["fields"] ] : []
        pk = haskey(d, "primaryKey") ? d["primaryKey"] : []
        if isa(pk, String); pk = [pk]; end
        fks = haskey(d, "foreignKeys") ? d["foreignKeys"] : []
        if isa(fks, String); fks = [fks]; end
        mvs = haskey(d, "missingValues") ? d["missingValues"] : []
        if isa(mvs, String); mvs = [mvs]; end

        # Validate schema types
        if !(isa(pk, Array))
            s = new([SchemaError("primaryKey must be a string array")], Dict(),[],[],[],[])
        elseif !(isa(fks, Array))
            s = new([SchemaError("foreignKeys must be a dictionary array")], Dict(),[],[],[],[])
        elseif !(isa(mvs, Array))
            s = new([SchemaError("missingValues must be a string array")], Dict(),[],[],[],[])
        else
            s = new([], d, pk, fks, mvs, fls)
        end

        # Detailed validation
        validate(s, strict)
    end

    function Schema(a::Array, strict::Bool=false)
        s = new([SchemaError("Descriptor must be an object, not an array")], Dict(),[],[],[],[])
        validate(s, strict)
    end

    Schema(filename::String, strict::Bool=false) =
        Schema(fetch_json(filename), strict)

    Schema(strict::Bool=false) =
        Schema(Dict(), strict)
end

function fetch_json(filename::String)
    if match(r"^https?://", filename) !== nothing
        req = request("GET", filename)
        JSON.parse(String(req.body))
    else
        JSON.parsefile(filename)
    end
end

function validate(s::Schema, strict::Bool=false)
    if isempty(s.descriptor)
        push!(s.errors, SchemaError("Missing Descriptor"))
    end
    if length(s.fields) == 0
        push!(s.errors, SchemaError("No Fields specified"))
    end

    # Validate each Field
    for fld in s.fields
        try
            validate(fld)
        catch ex
            if isa(ex, FieldError)
                push!(s.errors, SchemaError(ex))
            else
                throw(ex)
            end
        end
    end

    # Validate primary keys
    for key in s.primary_key
        if !(has_field(s, key))
            push!(s.errors, SchemaError("Missing field as defined in primaryKey", key))
        end
    end
    for e in s.errors
        if occursin(e.message, "primaryKey") && e.key != ""
            deleteat!(s.primary_key, findall(in([e.key]), s.primary_key))
        end
    end

    # Validate foreign keys
    for key in s.foreign_keys
        if !(haskey(key, "fields"))
            push!(s.errors, SchemaError("'fields' is required on all foreignKeys"))
            key["fields"] = []
        end
        if !(haskey(key, "reference"))
            push!(s.errors, SchemaError("'reference' is required on all foreignKeys"))
            key["reference"] = Dict()
        end
        if !(haskey(key["reference"], "resource"))
            push!(s.errors, SchemaError("'resource' is required on each reference of a foreignKey"))
            key["reference"]["resource"] = ""
        end
        if !(haskey(key["reference"], "fields"))
            push!(s.errors, SchemaError("'fields' is required on each reference of a foreignKey"))
            key["reference"]["fields"] = []
        end
        if isa(key["fields"], String)
            key["fields"] = [key["fields"]]
        end
        if isa(key["reference"]["fields"], String)
            key["reference"]["fields"] = [key["reference"]["fields"]]
        end
        # Validate field references
        for f in key["fields"]
            if !(has_field(s, f))
                push!(s.errors, SchemaError("Missing field as defined in foreignKeys fields", f))
            end
        end
        if key["reference"]["resource"] == ""
            for f in key["reference"]["fields"]
                if !(has_field(s, f))
                    push!(s.errors, SchemaError("Missing field as defined in foreignKeys references", f))
                end
            end
        end
        if length(key["fields"]) != length(key["reference"]["fields"])
            push!(s.errors, SchemaError("Number of source and outer foreign key references must match"))
        end
        # Handle errors
        for e in s.errors
            if occursin(e.message, "foreignKeys fields") && e.key != ""
                deleteat!(key["fields"],
                    findall(in([e.key]), key["fields"]))
            end
            if occursin(e.message, "foreignKeys references") && e.key != ""
                deleteat!(key["reference"]["fields"],
                    findall(in([e.key]), key["reference"]["fields"]))
            end
        end
    end

    # Error handling
    if strict && length(s.errors)>0
        throw(s.errors[1])
    end

    # TODO: find out why returning something else breaks the module
    s
end

function guess_type(value)
    if isa(value, Int)
        return "integer"
    elseif isa(value, Number)
        return "number"
    elseif isa(value, Bool)
        return "boolean"
    elseif isa(value, AbstractString)
        try
            df = DateFormat("YYYY-MM-DDThh:mm:ssZ")
            dd = Date(value, df)
            return "datetime"
        catch
            # continue
        end
        try
            df = DateFormat("HH:MM:SS")
            dd = Date(value, df)
            return "time"
        catch
            # continue
        end
        try
            df = DateFormat("y-m-d")
            dd = Date(value, df)
            return "date"
        catch
            # continue
        end
        gp = split(value, ",")
        if length(gp) == 2
            try
                lon = parse(Float64, gp[1])
                lat = parse(Float64, gp[2])
                if lon <= 180 && lon >= -180 &&
                    lat <= 90 && lat >= -90
                        return "geopoint"
                end
            catch
                # continue
            end
        end
        try
            obj = JSON.parse(value)
            if isa(obj, Array)
                return "array"
            elseif isa(obj, Dict)
                return "object"
            end
        catch
            # continue
        end
        return "string"
    else
        return nothing
    end
end

function infer(s::Schema, rows::Array{Any}, headers::Array{String}, maxrows=MAX_ROWS_INFER)
    for (c, header) in enumerate(headers)
        if has_field(s, header)
            continue
        end
        type_match = Dict()
        col = view(rows, :, c)
        if maxrows > length(col)
            maxrows = length(col)
        end
        for (r, val) in enumerate(col[1:maxrows])
            guess = guess_type(val)
            if guess == nothing
                @warn "Could not guess type at ($(r), $(c))"
            else
                if !haskey(type_match, guess)
                    type_match[guess] = 0
                end
                type_match[guess] = type_match[guess] + 1
                @debug "Guessed $(guess) at ($(r), $(c))"
            end
            # print(val)
            # print("\n")
        end
        f = Field(header)
        if length(type_match)>0
            sorted = sort(collect(type_match), by=x->x[2], rev=true)
            f.typed = sorted[1][1]
        end
        add_field(s, f)
    end
end

function set_primary_key(s::Schema, name::String)
    if !(has_field(s, name))
        throw(SchemaError("Fields defined as Primary Key must exist"))
    end
    if !(name in s.primary_key)
        push!(s.primary_key, name)
    end
end

function set_foreign_key(s::Schema, source_fields::Array{String}, resource::String, outer_fields::Array{String})
    for key in source_fields
        if !(has_field(s, key))
            throw(SchemaError("Source fields must reference existing schema fields"))
        end
    end
    if resource == ""
        for key in outer_fields
            if !(has_field(s, key))
                throw(SchemaError("Outer fields must reference existing schema fields to set empty reference"))
            end
        end
    end
    push!(s.foreign_keys, Dict(
            "fields" => source_fields,
            "reference" => Dict(
                "resource" => resource,
                "fields" => outer_fields
            )
        )
    )
end

function cast_row(s::Schema, row::Array, fail_fast=false, check_constraints=true)
    result = []; errors = []

    lrow = length(row); lsf = length(s.fields)
    (lrow != lsf) && throw(CastError(
        "Row length $lrow does not match fields count $lsf"))

    for (i, field) in enumerate(s.fields)
        value = row[i]
        try
            push!(result, cast_value(field, value, check_constraints))
        catch e
            if isa(e, CastError) && !fail_fast
                push!(errors, e)
            else
                throw(e)
            end
        end
    end

    le = length(errors)
    (le>0) && throw(CastError(
        "There are $le cast errors (see exception.errors)", errors))

    result
end

function build(s::Schema)
    d = Dict()
    d["fields"] = [ build(f) for f in s.fields ]
    d["primaryKey"] = s.primary_key
    d["foreignKeys"] = s.foreign_keys
    d["missingValues"] = s.missing_values
    s.descriptor = d
    d
end

function commit(s::Schema ; strict=nothing)
    strict !== nothing &&
        throw(ErrorException("strict parameter not implemented"))
    @debug "Building schema descriptor"
    s.descriptor = build(s)
    s.errors = []
    validate(s)
    length(s.errors) > 0 &&
        throw(ErrorException("Invalid schema: check errors"))
    true
end

function save(s::Schema, target::String)
    commit(s)
	indent = 4
	@debug "Saving table schema to $target"
	open(target, "w") do io
		JSON.print(io, s.descriptor, indent)
	end
end

field_names(s::Schema) = [ f.descriptor.name for f in s.fields ]
get_field(s::Schema, name::String) = [ f for f in s.fields if f.name == name ][1]
get_field_index(s::Schema, name::String) = findall(in([get_field(s, name)]), s.fields)
has_field(s::Schema, name::String) = length([ true for f in s.fields if f.name == name ]) > 0
add_field(s::Schema, d::Dict) = push!(s.fields, Field(d))
add_field(s::Schema, f::Field) = push!(s.fields, f)
remove_field(s::Schema, name::String) = deleteat!(s.fields, get_field_index(s, name))

is_empty(s::Schema) = Base.isempty(s.fields)
is_valid(s::Schema) = (!Base.isempty(s.descriptor) && length(s.errors) == 0)
