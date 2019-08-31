module CSVReader

using DataFrames: DataFrame, AbstractDataFrame, nrow
using InternedStrings: intern
using Parsers: tryparse

export @parsers_str

# This is twice as fast as the regular strip() function
faststrip(x, quotechar) = length(x) > 2 ? (x[1] == x[end] == quotechar ? x[2:end-1] : x) : x

# Parsers
parse_string(s) = intern(s)
parser_return_type(::Val{parse_string}) = Union{String, Missing}

parse_float64(s) = something(tryparse(Float64, s), missing)
parser_return_type(::Val{parse_float64}) = Union{Float64, Missing}

parse_int(s) = something(tryparse(Int, s), missing)
parser_return_type(::Val{parse_int}) = Union{Int, Missing}

"""
Construct parsers from a parser spec string.  The string contains a
comman separated value of the format <parser>:<length>.  For example,
s:10,f:2,i:5 means 10 strings, 2 floats, and 5 int's.
"""
macro parsers_str(s) 
    parser_dict = Dict("i" => parse_int, "f" => parse_float64, "s" => parse_string)
    parsers = []
    sep = ":"
    for spec ∈ split(s, ",")
        if occursin(sep, spec)
            T, L = split(spec, sep)     # f:10 => means 10 floats
            N = tryparse(Int, L)
            !haskey(parser_dict, T) && error("Invalid parser spec: $spec (unknown parser '$T')")
            (N == nothing || N <= 0) && error("Invalid parser spec: $spec (bad length '$N')")
            parsers = vcat(parsers, fill(parser_dict[T], N))
        else
            T = spec
            !haskey(parser_dict, T) && error("Invalid parser spec: $spec (unknown parser)")
            push!(parsers, parser_dict[T])
        end
    end
    parsers
end

"""
    Read CSV file

Read a CSV formatted file as specified by `filename`.  If `parsers` is not specified
then it is inferred from the first line.  Use `headers` keyword parameter to control
whether a header line is present for column names.
"""
# DataFrame approach but have a parsing state machine
function read_csv(filename, parsers = nothing; 
                    headers = true, 
                    delimiter = ',', 
                    quotechar = '"')  
    parsers = something(parsers, infer_parsers(filename, headers, delimiter, quotechar))
    est_lines = estimate_lines_in_file(filename, with_headers = headers)
    open(filename) do f
        hdr = read_headers(f, headers, delimiter, quotechar)
        r = 0
        preallocate_rows = est_lines
        df = make_dataframe(hdr, parser_return_type.(Val.(parsers)), preallocate_rows)
        @inbounds while !eof(f)
            line = readline(f)
            r += 1
            if r > preallocate_rows
                new_size = max(floor(Int, preallocate_rows * 1.05 + 5), preallocate_rows + 5)
                @debug "Growing data frame from $preallocate_rows rows to $new_size"
                grow_dataframe!(df, new_size)
                preallocate_rows = new_size
            end 
            # This state machine keeps track of two indices (i,j).
            # The value of `j` is incremented until it hits a delimiter or end of string.
            # The value of `k` is then determined as `j-1` if line[j] is a delimiter,
            # else `k` would have the same index as `end` of line.
            # The cell is then consumed i.e. stripped, parsed, and set.
            # Reference: i = start, j = pointer, k = end, c = column index
            len = length(line)
            i = j = c = 1
            within_quote = false
            while i <= len && j <= len
                if line[j] == quotechar
                    within_quote = !within_quote
                end
                if (!within_quote && line[j] == delimiter) || j == len
                    k = (j == len) ? len : j-1  # special case at end of line
                    df[r, c] = faststrip(line[i:k], quotechar) |> parsers[c]
                    c += 1
                    i = j = j+1
                else
                    j += 1
                end
            end
            # parse_line!(df, r, parsers, line, delimiter, quotechar)
        end
        trim_table(df, r)
    end
end

"""
Peek into first few lines of CSV file
"""
function peek_csv(filename; headers = true, nrows = 5, delimiter = ',', quotechar = '"')
    open(filename) do f
        headers = read_headers(f, headers, delimiter, quotechar)
        rows = read_first_few_lines(f, nrows)
        column_names = [split(row, delimiter) for row ∈ rows]
        ncols = maximum(length(x) for x ∈ column_names)
        @info "Peeking into first few rows => there are $ncols columns" rows
    end
    nothing
end

# Warning: type piracy!
function grow_dataframe!(df::AbstractDataFrame, rows::Integer)
    rows <= nrow(df) && error("Current data frame has $(nrow(df)) rows but you specified to grow to $rows rows!")
    for c ∈ names(df)
        df[c] = resize!(df[c], rows)
    end
    nothing
end

function parse_line!(df, row, parsers, line, delimiter, quotechar)
    strings = split(line, delimiter)
    for (i, parser) ∈ enumerate(parsers)
        parsed_value = faststrip(strings[i], quotechar) |> parser
        #@debug "Parsed line" row i parsed_value
        df[row,i] = parsed_value
    end
    nothing
end

# Make a new DataFrame
function make_dataframe(hdr, types, rows)
    # @info "Making table with $rows rows"
    # @info "Types = $types"
    # @info "Types[11] = $(types[11])"
    hdr = something(hdr, ["_$i" for i ∈ 1:length(types)])
    cols = [Vector{T}(undef, rows) for T ∈ types]
    df = DataFrame(cols, Symbol.(hdr), makeunique = true)
    df
end

function trim_table(df, rows)
    @debug "Trimming table" nrow(df) rows
    df[1:rows, :]
end

function read_headers(f, headers, delimiter, quotechar)
    if headers
        map(h -> faststrip(h, quotechar), split(readline(f), delimiter))
    else
        nothing
    end
end

function infer_parsers(filename, headers, delimiter, quotechar)
    open(filename) do f
        headers && readline(f)
        first_line = readline(f)
        cells = map(x -> faststrip(x, quotechar), split(first_line, delimiter))
        infer_parser.(cells) 
    end
end

# infer parser needed from a string
function infer_parser(s)
    if match(r"^\d+\.\d*$", s) != nothing ||      # covers 12.
            match(r"^\d*\.\d+$", s)!= nothing ||  # covers .12
            match(r"^\d+\.\d*e[+-]\d$", s) != nothing
        parse_float64
    elseif match(r"^\d+$", s) != nothing          # covers 123
        parse_int
    else
        parse_string
    end
end

# get some sample lines
function get_sample_lines(filename; headers = true, max_reach_pct = 0.1, samples_pct = 0.1, max_samples = 10)
    L = estimate_lines_in_file(filename)
    L_upper = floor(Int, L * max_reach_pct)   # don't read lines further than this
    L_lower = headers ? 2 : 1
    num_samples = min(max_samples, floor(Int, L_upper * samples_pct))
    @info "There are approximately $L lines in the file"
    @info "Taking at most $(num_samples) samples between L$(L_lower) and L$(L_upper)"
    samples = unique(sort(rand(L_lower:L_upper, num_samples)))
    n = 1
    i = 1
    lines = String[]
    open(filename) do f
        while !eof(f)
            line = readline(f)
            if n == samples[i]   # take sample
                push!(lines, line)
                i += 1
                i > length(samples) && break
            end
            n += 1
        end
    end
    lines
end

function estimate_lines_in_file(filename; line_length_samples = 10, with_headers = true)
    s = filesize(filename)
    open(filename) do f
        with_headers && readline(f)  # skip header
        L =  estimate_line_length(f, line_length_samples)
        L > 0 ? s ÷ L : 0
    end
end

function estimate_line_length(f, line_length_samples)
    few_lines = read_first_few_lines(f, line_length_samples)
    if length(few_lines) > 0
        sum(length, few_lines) ÷ length(few_lines)
    else
        0
    end
end

function read_first_few_lines(f, lines_to_read)
    lines = String[]
    count = 0
    while !eof(f) && count < lines_to_read
        line = readline(f)
        push!(lines, line)
        count += 1
    end
    lines
end

# -------------------
# Experimental stuffs
# -------------------

# Return vector of named tuples
function read_csv_nt(filename, parsers = nothing; 
                        headers = true, 
                        delimiter = ',', 
                        quotechar = '"')  
    parsers = something(parsers, infer_parsers(filename, headers, delimiter, quotechar))
    result = Vector{NamedTuple}()
    open(filename) do f
        # header symbols
        hdr = read_headers(f, headers, delimiter, quotechar)
        hdr = something(hdr, ["_$i" for i ∈ 1:length(parsers)])
        hdr = Tuple(Symbol.(hdr))
        ncol = length(parsers)
        r = 0
        v = Any[nothing for _ in 1:ncol]
        T = NamedTuple{hdr}
        while !eof(f)
            line = readline(f)
            r += 1
            s = split(line, delimiter)
            @inbounds for i in 1:ncol
                v[i] = faststrip(s[i], quotechar) |> parsers[i]
            end
            push!(result, T(v))
        end
    end
    result
end

# Return vector of named tuples but also have a parsing state machine
function read_csv_nt2(filename, parsers = nothing; 
                    headers = true, 
                    delimiter = ',', 
                    quotechar = '"')  
    parsers = something(parsers, infer_parsers(filename, headers, delimiter, quotechar))
    open(filename) do f
        # header symbols
        hdr = read_headers(f, headers, delimiter, quotechar)
        hdr = something(hdr, ["_$i" for i ∈ 1:length(parsers)])
        hdr = Tuple(Symbol.(hdr))
        ncol = length(parsers)
        r = 0
        v = Any[nothing for _ in 1:ncol]
        T = NamedTuple{hdr}
        result = Vector{T}()
        while !eof(f)
            line = readline(f)
            len = length(line)
            i = j = c = 1
            while i <= len && j <= len
                if line[j] == delimiter || j == len
                    k = (j == len) ? len : j-1  # special case at end of line
                    v[c] = faststrip(line[i:k], quotechar) |> parsers[c]
                    c += 1
                    i = j = j+1
                else
                    j += 1
                end
            end
            push!(result, T(v))
        end
        result
    end
end

end # module

