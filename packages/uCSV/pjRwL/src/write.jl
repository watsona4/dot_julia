"""
    function write(output;
                   header=missing,
                   data=missing,
                   delim=',',
                   quotes=missing,
                   quotetypes=AbstractString)

Write a dataset to disk or IO

# Arguments
- `output`
    - the path on disk or IO where you want to write to
- `header`
    - the column names for the data to `output`
    - default: `header=missing`
        - no header is written
- `data`
    - the dataset to write to `output`
    - default: `data=missing`
        - no data is written
- `delim`
    - the delimiter to seperate fields by
    - default: `delim=','`
        - for CSV files
    - frequently used:
        - `delim='\\t'`
        - `delim=' '`
        - `delim='|'`
- `quotes`
    - the quoting character to use when writing fields
    - default: `quotes=missing`
        - fields are not quoted by default, and fields are written using julia's
          default string-printing mechanisms
- `quotetypes::Type`
    - when quoting fields, quote only columns where `coltype <: quotetypes`
        - columns of type `Union{<:quotetypes, Missing}` will also be quoted
    - default: `quotetypes=AbsractString`
        - only the header and fields where `coltype <: AbsractString` will be quoted
    - frequently used:
        - `quotetypes=Any`
            - quote every field in the dataset
"""
function write(fullpath::Union{String, IO};
               header::Union{AbstractVector{String}, Missing}=missing,
               data::Union{AbstractVector{<:Any}, Missing}=missing,
               delim::Union{Char, String}=',',
               quotes::Union{Char, Missing}=missing,
               quotetypes::Type=AbstractString)
    if ismissing(header) && ismissing(data)
        throw(ArgumentError("no header or data provided"))
    elseif !ismissing(data)
        @assert length(unique(length.(data))) == 1
        if !ismissing(header)
            @assert length(header) == length(data)
        end
    end
    if isa(fullpath, IO)
        if iswritable(fullpath)
            f = fullpath
        else
            throw(ArgumentError("""
                                Provided IO is not writable
                                """))
        end
    else
        f = open(fullpath, "w")
    end
    if !ismissing(header)
        if !ismissing(quotes)
            for i in eachindex(header)
                header[i] = string(quotes, header[i], quotes)
            end
        end
        Base.write(f, join(header, delim) * "\n")
    end
    if !ismissing(data)
        numcols = length(data)
        eltypes = eltype.(data)
        for row in 1:length(data[1])
            rowvalues = [string(data[col][row]) for col in 1:numcols]
            if !ismissing(quotes)
                for i in findall(e -> e <: quotetypes || (e != Missing && e <: Union{quotetypes, Missing}), eltypes)
                    rowvalues[i] = string(quotes, rowvalues[i], quotes)
                end
            end
            Base.write(f, join(rowvalues, delim) * "\n")
        end
    end
    close(f)
end

"""
    function write(output,
                   df;
                   delim=',',
                   quotes=missing,
                   quotetypes=AbstractString)

Write a DataFrame to disk or IO
"""
function write(fullpath, df::DataFrame; kwargs...)
    write(fullpath; header = string.(names(df)), data = DataFrames.columns(df), kwargs...)
end
