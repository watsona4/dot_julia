"""
Table Schema generic data structure
https://github.com/frictionlessdata/tableschema-jl#table
"""
mutable struct Table
    source
    headers::Array{String}
    schema::Schema
    errors::Array{ConstraintError}

    function Table(csvfilename::String, schema::Schema=Schema())
        if match(r"^https?://", csvfilename) !== nothing
            source = read_remote_csv(csvfilename)
        else
            source = readdlm(csvfilename, ',')
        end
        headers, source = get_headers(source)
        new(source, headers, schema, [])
    end
    function Table(csvdata::Base.GenericIOBuffer, schema::Schema=Schema())
        source = readdlm(csvdata, ',')
        headers, source = get_headers(source)
        new(source, headers, schema, [])
    end
    function Table(source, headers::Array{String}, schema::Schema=Schema())
        new(source, headers, schema, [])
    end
    function Table()
        new(Nothing, [], Schema(), [])
    end
end

function read_remote_csv(url::String)
    req = request("GET", url)
    readdlm(req.body, ',')
end

function get_headers(source::Array)
    headers = [ String(s) for s in source[1,:] ]
    headers, source[2:end,:] # clear the headers
end

function read(t::Table ; data=nothing, keyed=false, extended=false, cast=true, relations=false, limit=nothing)
    (keyed == false && extended == false && relations == false && limit == nothing) || throw(ErrorException("Not implemented"))
    if data != nothing
        if typeof(data) == Array{Any, 2}
            t.headers, t.source = get_headers(data)
        else
            throw(ErrorException("Data must be a 2-dimensional array"))
        end
    end
    if cast
        if !is_valid(t.schema)
            throw(ErrorException("Schema must be valid to cast Table"))
        end
        if t.source == nothing
            throw(ErrorException("Data must be available to cast Table"))
        end
        newtable = Nothing
		# Iterate table rows
        for row in t
			# Apply cast to the row's values
            newrow = cast_row(t.schema, row, false, false)
			# Reshape back into a non-elemental array
			newrow = reshape(newrow, 1, length(newrow))
            if newtable == Nothing
                newtable = newrow
            else
                newtable = vcat(newtable, newrow)
            end
        end
        t.source = newtable
    end
    t.source
end

function infer(t::Table ; limit::Int64=-1)
	# what
	limit !== -1 && throw(ErrorException("limit parameter not implemented"))
	tr = read(t, cast=false)
	t.schema = Schema()
	infer(t.schema, tr, t.headers)
end

function save(t::Table, target::String)
	# TODO: should we check the schema too?
	# !valid(t.schema) &&
    #     throw(TableValidationException("Schema not valid"))
	@debug "Building table data"
	headers = reshape(t.headers, 1, length(t.headers))
	tabledata = vcat(headers, t.source)
	@debug "Saving table data to $target"
	delim = ','
	open(target, "w") do io
		writedlm(io, tabledata, delim)
	end
end

function validate(t::Table)
    is_empty(t.schema) &&
        throw(TableValidationException("No schema available"))
    # TODO: should we check the schema too?
    # !valid(t.schema) &&
    #     throw(TableValidationException("Schema not valid"))
    tr = t.source
    for fld in t.schema.fields
        ix = findall(in([fld.name]), t.headers)
        if length(ix) != 1
            # TODO: shouldn't this just cause a ConstraintError?
            throw(TableValidationException(string("Missing field defined in Schema: ", fld.name)))
        end
        try
            column = tr[:,ix]
            for r = 1:size(tr, 2)
                row = tr[r,:]
                checkrow(fld, row[ix[1]], column)
            end
        catch ex
            if isa(ex, ConstraintError)
                push!(t.errors, ex)
            end
        end
    end
    # foreach(r -> println(r.message,"-",r.value,"-",r.field.name), t.errors)
    # message =
    #     'Field "{field.name}" has constraint "{name}" '
    #     'which is not satisfied for value "{value}"'
    #     ).format(field=self, name=name, value=value))
    return length(t.errors) == 0
end

Base.eltype(it::Table) = Table
Base.length(it::Table) = size(it.source, 1)
function Base.iterate(it::Table, (el, i)=(nothing, 1))
    if i > length(it); return nothing; end
    return (it.source[i,:], (nothing, i + 1))
end

# Base.start(t::Table) = 1
# Base.done(t::Table, i) = i > size(t.source, 1)
# Base.next(t::Table, i) = t.source[i,:], i+1
