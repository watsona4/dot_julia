"""
    read(input;
         delim=',',
         quotes=missing,
         escape=missing,
         comment=missing,
         encodings=Dict{String, Any}(),
         header=0,
         skiprows=Vector{Int}(),
         types=Dict{Int,DataType}(),
         allowmissing=Dict{Int,Bool}(),
         coltypes=Vector,
         colparsers=Dict{Int,Function}(),
         typeparsers=Dict{DataType, Function}(),
         typedetectrows=1,
         skipmalformed=false,
         trimwhitespace=false)

Take an input file or IO source and user-defined parsing rules and return:
1. a `Vector{Any}` containing the parsed columns
2. a `Vector{String}` containing the header (column names)

# Arguments
- `input`
    - the path to a local file, or an open IO source from which to read data
- `delim`
    - a `Char` or `String` that separates fields in the dataset
    - default: `delim=','`
        - for CSV files
    - frequently used:
        - `delim='\\t'`
        - `delim=' '`
        - `delim='|'`
- `quotes`
    - a `Char` used for quoting fields in the dataset
    - default: `quotes=missing`
        - by default, the parser does not check for quotes
    - frequently used:
        - `quotes='"'`
- `escape`
    - a `Char` used for escaping other reserved parsing characters
    - default: `escape=missing`
        - by default, the parser does not check for escapes
    - frequently used:
        - `escape='"'`
            - double-quotes within quotes, e.g. `"firstname ""nickname"" lastname"`
        - `escape='\\\\'`
            - note that the first backslash is just to escape the second backslash
            - e.g. `"firstname \\\"nickname\\\" lastname"`
- `comment`
    - a `Char` or `String` at the beginning of lines that should be skipped as comments
        - note that skipped comment lines do not contribute to the line count for the header
          (if the user requests parsing a header on a specific row) or for skiprows
    - default: `comment=missing`
        - by default, the parser does not check for comments
    - frequently used:
        - `comment='#'`
        - `comment='!'`
        - `comment="#!"`
- `encodings`
    - a `Dict{String, Any}` mapping parsed fields to Julia values
        - if your dataset has booleans that are not represented as `"true"` and `"false"` or missing values that you'd like to read as `missing`s, you'll need to use this!
    - default: `encodings=Dict{String, Any}()`
        - by default, the parser does not check for any reserved fields
    - frequently used:
        - `encodings=Dict("" => missing)`
        - `encodings=Dict("NA" => missing)`
        - `encodings=Dict("N/A" => missing)`
        - `encodings=Dict("NULL" => missing)`
        - `encodings=Dict("TRUE" => true, "FALSE" => false)`
        - `encodings=Dict("True" => true, "False" => false)`
        - `encodings=Dict("T" => true, "F" => false)`
        - `encodings=Dict("yes" => true, "no" => false)`
        - ... your encodings here ...
            - can include any number of `String` => value mappings
            - note that if the user requests `quotes`, `escapes`, or `trimwhitespace`, these requests
              will be applied (removed) the raw string *BEFORE* checking whether the field matches
              any strings in in the `encodings` argument
- `header`
    - an `Int` indicating which line of the dataset contains column names or a `Vector{String}` of column names
        - note that commented lines and blank lines do not contribute to this value
          e.g. if the first 3 lines of your dataset are comments, you'll still need to
          set `header=1` to interpret the first line of parsed data as the header
    - default: `header=0`
        - no header is checked for by default
    - frequently used:
        - `header=1`
- `skiprows`
    - a `Range` or `Vector` of `Int`s indicating which rows to skip in the dataset
        - note that this is 1-based in reference to the first row *AFTER* the header.
          if `header=0` or is provided by the user, this will be the first non-empty
          line in the dataset. otherwise `skiprows=1:1` will skip the `header+1`-nth line
          in the file
    - default: `skiprows=Vector{Int}()`
        - no rows are skipped
- `types`
    - declare the types of the columns
        - scalar, e.g. `types=Bool`
            - scalars will be broadcast to apply to every column of the dataset
        - vector, e.g. `types=[Bool, Int, Float64, String, Symbol, Date, DateTime]`
            - the vector length must match the number of parsed columns
        - dictionary, e.g. `types=("column1" => Bool)` or `types=(1 => Union{Int, Missing})`
            - users can refer to the columns by name (only if a header is provided or
              parsed!) or by index
    - default:
        - `types=Dict{Int,DataType}()`
            - column-types will be interpreted from the dataset
    - built-in support for parsing the following:
        - `Int`
        - `Float64`
        - `String`
        - `Symbol`
        - `Date` -- only the default date format will work
        - `DateTime` -- only the default datetime format will work
        - for other types or unsupported formats, see `colparsers` and `typeparsers`
- `allowmissing`
    - declare whether columns should have element-type `Union{T, Missing} where T`
        - boolean scalar, e.g. `allowmissing=true`
            - scalars will be broadcast to apply to every column of the dataset
        - vector, e.g. `allowmissing=[true, false, true, true]`
            - the vector length must match the number of parsed columns
        - dictionary, e.g. `allowmissing=("column1" => true)` or `allowmissing=(17 => true)`
            - users can refer to the columns by name (only if a header is provided or
              parsed!) or by index
    - default: `allowmissing=Dict{Int,Bool}()`
        - Allowing missing values is determined by type detection in rows `1:typedetectrows`
- `coltypes`
    - declare the type of vector that should be used for columns
    - should work for any AbstractVector that allows `push!`ing values
        - scalar, e.g. `coltypes=CategoricalVector`
            - scalars will be broadcast to apply to every column of the dataset
        - vector, e.g. `coltypes=[CategoricalVector, Vector, CategoricalVector]`
            - the vector length must match the number of parsed columns
        - dictionary, e.g. `coltypes=("column1" => CategoricalVector)` or `coltypes=(17 => CategoricalVector)`
            - users can refer to the columns by name (only if a header is provided or
              parsed!) or by index
    - default: `coltypes=Vector`
        - all columns are returned as standard julia `Vector`s
- `colparsers`
    - provide custom functions for converting parsed strings to values by column
        - scalar, e.g. `colparsers=(x -> parse(Float64, replace(x, ',', '.')))`
            - scalars will be broadcast to apply to every column of the dataset
        - vector, e.g. `colparsers=[x -> mydateparser(x), x -> mytimeparser(x)]`
            - the vector length must match the number of parsed columns
        - dictionary, e.g. `colparsers=("column1" => x -> mydateparser(x))`
            - users can refer to the columns by name (only if a header is provided or
              parsed!) or by index
    - default: `colparsers=Dict{Int,Function}()`
        - column parsers are determined based on user-specified types and those
          detected from the data
- `typeparsers`
    - provide custom functions for converting parsed strings to values by column type
        - *NOTE* must be used with `coltypes`. If you supply a custom Int parser you'd like to
          use to parse column 6, you'll need to set `coltypes=dict(6 => Int)` for it to work
    - default: `colparsers=Dict{DataType, Function}()`
        - column parsers are determined based on user-specified types and those
          detected from the data
    - frequently used:
        - `typeparsers=Dict(Float64 => x -> parse(Float64, replace(x, ',' => '.')))` # decimal-comma floats!
- `typedetectrows`
    - specify how many rows of data to read before interpretting the values that each
      column should take on
    - default: `typedetectrows=1`
        - must be >= 1
        - commented, skipped, and empty lines are not counted when determining
          which rows are used for type detection, e.g. setting `typedetectrows=10` and
          `skiprows=1:5` means type detection will occur on rows `6:15`
- `skipmalformed`
    - specify whether the parser should skip a line or fail with an error if a line is
      parsed but does not contain the expected number of rows
    - default: `skipmalformed=false`
        - malformed lines result in an error
- `trimwhitespace`
    - specify whether should extra whitespace be removed from the beginning and ends of fields.
        - e.g `...., myfield ,...`
            - `trimwhitespace=false` -> `" myfield "`
            - `trimwhitespace=true`  -> `"myfield"`
    - leading and trailing whitespace *OUTSIDE* of quoted fields is trimmed by default.
        - e.g. `...., " myfield " ,...` -> `" myfield "` when `quotes='"'`
    - `trimwhitespace=true` will also trim leading and trailing whitespace *WITHIN* quotes
    - default: `trimwhitespace=false`
"""
function read(source::IO;
              delim::Union{Char,String}=',',
              quotes::Union{Char,Missing}=missing,
              escape::Union{Char,Missing}=missing,
              comment::Union{Char,String,Missing}=missing,
              encodings::Dict{String,T} where T=Dict{String,Any}(),
              header::Union{Integer,Vector{String}}=0,
              skiprows::AbstractVector{Int}=Vector{Int}(),
              types::Union{T1,COLMAP{T1},Vector{T1}} where {T1<:Type}=Dict{Int,DataType}(),
              allowmissing::Union{Bool,COLMAP{Bool},Vector{Bool}}=Dict{Int,Bool}(),
              coltypes::Union{Type{<:AbstractVector},COLMAP{UnionAll},Vector{UnionAll}}=Vector,
              colparsers::Union{F1, COLMAP{F1}, Vector{F1}} where F1=Dict{Int,Function}(),
              typeparsers::Dict{T2, F2} where {T2<:Type, F2}=Dict{DataType, Function}(),
              typedetectrows::Int=1,
              skipmalformed::Bool=false,
              trimwhitespace::Bool=false)

        reserved = [x for x in (delim, quotes, escape, comment) if !ismissing(x)]
        if !ismissing(quotes) && isequal(quotes, escape)
            @assert length(unique(string.(reserved))) == length(reserved) - 1
        else
            @assert length(unique(string.(reserved))) == length(reserved)
        end
        if isa(coltypes, Vector{UnionAll})
            @assert all(x -> x <: AbstractVector, coltypes)
        elseif isa(coltypes, COLMAP{UnionAll})
            @assert all(x -> x <: AbstractVector, collect(values(coltypes)))
        end
        @assert typedetectrows >= 1
        if typedetectrows > 100
            @warn """
                  Large values for `typedetectrows` will reduce performance. Consider manually declaring the types of columns using the `types` argument instead.
                  """
        end
        return parsesource(source, delim, quotes, escape, comment, encodings, header,
                           skiprows, types, allowmissing, coltypes, colparsers, typeparsers,
                           typedetectrows, skipmalformed, trimwhitespace)
end

function read(fullpath::String; kwargs...)
    read(open(fullpath); kwargs...)
end
