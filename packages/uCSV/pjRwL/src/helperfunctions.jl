function getintdict(arg::Vector, numcols::Int, colnames::Vector{String})
    if length(arg) != numcols
        throw(ArgumentError("""
                            One of the following user-supplied arguments:
                              1. types
                              2. allowmissing
                              3. coltypes
                              4. colparsers
                            was provided as a vector and the length of this vector ($(length(arg))) != the number of detected columns ($numcols).
                            """))
    end
    return Dict(i => arg[i] for i in 1:length(arg))
end

function getintdict(arg::Dict{String, T}, numcols::Int, colnames::Vector{String}) where T
    if isempty(colnames)
        throw(ArgumentError("""
                            One of the following user-supplied arguments:
                              1. types
                              2. allowmissing
                              3. coltypes
                              4. colparsers
                            was provided with column names as Strings that cannot be mapped to column indices because column names have either not been provided or have not been parsed.
                            """))
    end
    if all(k -> in(k, colnames), keys(arg))
        return Dict(something(findfirst(colnames .== k), 0) => v for (k,v) in arg)
    else
        k = first(filter(k -> !in(k, colnames), collect(keys(arg))))
        throw(ArgumentError("""
                            user-provided column name $k does not match any parsed or user-provided column names.
                            """))
    end
end

function getintdict(arg::Dict{Int, T}, numcols::Int, colnames::Vector{String}) where T
    return arg
end

function getintdict(arg, numcols::Int, colnames::Vector{String})
    return Dict(i => arg for i in 1:numcols)
end

function handlemalformed(expected::Int, observed::Int, currentline::Int, skipmalformed::Bool, line)
    if skipmalformed
        @warn """
              Parsed $observed fields on row $currentline. Expected $expected. Skipping...
              """
    else
        throw(ErrorException("""
                         Parsed $observed fields on row $currentline. Expected $expected.
                         line:
                         $line
                         Possible fixes may include:
                           1. including $currentline in the `skiprows` argument
                           2. setting `skipmalformed=true`
                           3. if this line is a comment, setting the `comment` argument
                           4. if fields are quoted, setting the `quotes` argument
                           5. if special characters are escaped, setting the `escape` argument
                           6. fixing the malformed line in the source or file before invoking `uCSV.read`
                         """))
    end
end

function _readline(source, comment::Missing)
    line = readline(source)
    while isempty(line) && !eof(source)
        line = readline(source)
    end
    return line
end

function _readline(source, comment)
    line = readline(source)
    while (startswith(line, comment) || isempty(line)) && !eof(source)
        line = readline(source)
    end
    return line
end

function DataFrames.DataFrame(output::Tuple{Vector{Any}, Vector{String}}; kwargs...)
    data = output[1]
    header = output[2]
    if isempty(header)
        return DataFrames.DataFrame(data, Symbol.(["x$i" for i in 1:length(data)]); kwargs...)
    elseif isempty(data)
        return DataFrames.DataFrame(Any[[] for i in 1:length(header)], Symbol.(header); kwargs...)
    else
        return DataFrames.DataFrame(data, Symbol.(header); kwargs...)
    end
end

"Convert the data output by uCSV.read to a `Matrix`. Column names are ignored"
function tomatrix(output::Tuple{Vector{Any}, Vector{String}})
    data = output[1]
    nrows = length(data)
    ncols = length(data[1])
    m = Array{promote_type(eltype.(data)...)}(undef, nrows, ncols)
    for col in 1:ncols
        m[:, col] .= data[col]
    end
    return m
end

"Convert the data output by uCSV.read to a `Vector`. Column names are ignored"
function tovector(output::Tuple{Vector{Any}, Vector{String}})
    m = tomatrix(output)
    return reshape(m, reduce(*, size(m)))
end

function throwbadbreak(location, line, quotes)
    if isa(quotes, Missing)
        throw(ErrorException("""
                             Unexpected field breakpoint detected in $location.
                             line:
                                $line
                             """))
    else
        throw(ErrorException("""
                             Unexpected field breakpoint detected in $location.
                             line:
                                $line
                             This may be due to nested double quotes `$quotes$quotes` within quoted fields.
                             If so, please set `escape=$quotes` to resolve
                             """))
    end
end

function throwbadconversion(f, currentline, i, encodings, data)
    if haskey(encodings, f)
        throw(ErrorException("""
                             Error parsing field "$f" in row $currentline, column $i.
                             Unable to push value $(encodings[f]) to column of type $(eltype(data[i]))
                             Possible fixes may include:
                               1. set `typedetectrows` to a value >= $currentline
                               2. manually specify the element-type of column $i via the `types` argument
                               3. manually specify a parser for column $i via the `parsers` argument
                               4. if the value is missing, setting the `allowmissing` argument
                             """))
    else
        throw(ErrorException("""
                             Error parsing field "$f" in row $currentline, column $i.
                             Unable to parse field "$f" as type $(eltype(data[i]))
                             Possible fixes may include:
                               1. set `typedetectrows` to a value >= $currentline
                               2. manually specify the element-type of column $i via the `types` argument
                               3. manually specify a parser for column $i via the `parsers` argument
                               4. if the intended value is missing or another special encoding, setting the `encodings` argument appropriately.
                             """))
    end
end

function throwcolumnnumbermismatch(header, colnames, numcols)
    if isa(header, Int)
        throw(ErrorException("""
                             parsed header $colnames has $(length(colnames)) columns, but $numcols were detected the in dataset.
                             """))
    else
        throw(ArgumentError("""
                            user-provided header $header has $(length(header)) columns, but $numcols were detected the in dataset.
                            """))
    end
end
