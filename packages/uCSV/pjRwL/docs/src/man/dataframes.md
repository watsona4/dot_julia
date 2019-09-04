# Reading into DataFrames

uCSV implements a convenience constructor for `DataFrame`s that takes the output of `uCSV.read`
(a `Tuple{Vector::Any, Vector{String}}`) and converts it to a `DataFrame`.

!!! note

    When NamedTuples becomes available in a future release of Julia, uCSV read will return
    the data as a `NamedTuple` and this function will be deprecated (since `DataFrame`s
    will implement its own constructor for NamedTuples)

```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       1.0,1.0,1.0
       2.0,2.0,2.0
       3.0,3.0,3.0
       """;

julia> DataFrame(uCSV.read(IOBuffer(s)))
3×3 DataFrames.DataFrame
│ Row │ x1      │ x2      │ x3      │
│     │ Float64 │ Float64 │ Float64 │
├─────┼─────────┼─────────┼─────────┤
│ 1   │ 1.0     │ 1.0     │ 1.0     │
│ 2   │ 2.0     │ 2.0     │ 2.0     │
│ 3   │ 3.0     │ 3.0     │ 3.0     │
```

And again, but with a header
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       c1,c2,c3
       1,1.0,a
       2,2.0,b
       3,3.0,c
       """;

julia> DataFrame(uCSV.read(IOBuffer(s), header = 1))
3×3 DataFrames.DataFrame
│ Row │ c1    │ c2      │ c3     │
│     │ Int64 │ Float64 │ String │
├─────┼───────┼─────────┼────────┤
│ 1   │ 1     │ 1.0     │ a      │
│ 2   │ 2     │ 2.0     │ b      │
│ 3   │ 3     │ 3.0     │ c      │

```
