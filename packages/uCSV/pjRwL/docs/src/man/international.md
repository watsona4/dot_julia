# International Representations for Numbers

Julia enforces conventions for parsing numbers and dates that are very prevelant, but not universal. `uCSV.read` exposes a parsing API that allows users to parse international and non-standard formats. A very commonly encountered format that will used for the following examples is [decimal-comma floats](https://en.wikipedia.org/wiki/Decimal_mark#Hindu.E2.80.93Arabic_numeral_system).

Users can override the default `Float64` parsing function from Julia as long as they also declare which columns this parser should be applied to
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       19,97;3,14;999
       """;

julia> imperialize(x) = parse(Float64, replace(x, ',' => '.'))
imperialize (generic function with 1 method)

julia> DataFrame(uCSV.read(IOBuffer(s), delim=';', types=Dict(1 => Float64, 2 => Float64), typeparsers=Dict(Float64 => x -> imperialize(x))))
1×3 DataFrames.DataFrame
│ Row │ x1      │ x2      │ x3    │
│     │ Float64 │ Float64 │ Int64 │
├─────┼─────────┼─────────┼───────┤
│ 1   │ 19.97   │ 3.14    │ 999   │

```

Users can also declare custom parsers by column
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       19,97;3,14;999
       """;

julia> imperialize(x) = parse(Float64, replace(x, ',' => '.'))
imperialize (generic function with 1 method)

julia> DataFrame(uCSV.read(IOBuffer(s), delim=';', colparsers=Dict(1 => x -> imperialize(x), 2 => x -> imperialize(x))))
1×3 DataFrames.DataFrame
│ Row │ x1      │ x2      │ x3    │
│     │ Float64 │ Float64 │ Int64 │
├─────┼─────────┼─────────┼───────┤
│ 1   │ 19.97   │ 3.14    │ 999   │

```
