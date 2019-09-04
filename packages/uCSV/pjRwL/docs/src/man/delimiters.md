# Delimiters

Commas are used by default
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       1,2,3
       """
"1,2,3\n"

julia> DataFrame(uCSV.read(IOBuffer(s)))
1×3 DataFrames.DataFrame
│ Row │ x1    │ x2    │ x3    │
│     │ Int64 │ Int64 │ Int64 │
├─────┼───────┼───────┼───────┤
│ 1   │ 1     │ 2     │ 3     │

```

Spaces can be used
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       1 2 3
       """
"1 2 3\n"

julia> DataFrame(uCSV.read(IOBuffer(s), delim=' '))
1×3 DataFrames.DataFrame
│ Row │ x1    │ x2    │ x3    │
│     │ Int64 │ Int64 │ Int64 │
├─────┼───────┼───────┼───────┤
│ 1   │ 1     │ 2     │ 3     │

```

So can Tabs
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       1\t2\t3
       """
"1\t2\t3\n"

julia> DataFrame(uCSV.read(IOBuffer(s), delim='\t'))
1×3 DataFrames.DataFrame
│ Row │ x1    │ x2    │ x3    │
│     │ Int64 │ Int64 │ Int64 │
├─────┼───────┼───────┼───────┤
│ 1   │ 1     │ 2     │ 3     │

```

So can Strings
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       1||2||3
       """
"1||2||3\n"

julia> DataFrame(uCSV.read(IOBuffer(s), delim="||"))
1×3 DataFrames.DataFrame
│ Row │ x1    │ x2    │ x3    │
│     │ Int64 │ Int64 │ Int64 │
├─────┼───────┼───────┼───────┤
│ 1   │ 1     │ 2     │ 3     │

```

non-ASCII characters work just fine
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       1˚2˚3
       """
"1˚2˚3\n"

julia> DataFrame(uCSV.read(IOBuffer(s), delim='˚'))
1×3 DataFrames.DataFrame
│ Row │ x1    │ x2    │ x3    │
│     │ Int64 │ Int64 │ Int64 │
├─────┼───────┼───────┼───────┤
│ 1   │ 1     │ 2     │ 3     │

```

non-ASCII strings work too
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       1≤≥2≤≥3
       """
"1≤≥2≤≥3\n"

julia> DataFrame(uCSV.read(IOBuffer(s), delim="≤≥"))
1×3 DataFrames.DataFrame
│ Row │ x1    │ x2    │ x3    │
│     │ Int64 │ Int64 │ Int64 │
├─────┼───────┼───────┼───────┤
│ 1   │ 1     │ 2     │ 3     │

```
