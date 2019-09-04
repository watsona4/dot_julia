# Skipping Comments and Rows

Skipping comments by declaring what commented lines start with
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       # i am a comment
       data
       """;

julia> DataFrame(uCSV.read(IOBuffer(s), comment='#'))
1×1 DataFrames.DataFrame
│ Row │ x1     │
│     │ String │
├─────┼────────┤
│ 1   │ data   │

```

Skipping comments by declaring what line the dataset starts on
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       # i am a comment
       data
       """;

julia> DataFrame(uCSV.read(IOBuffer(s), skiprows=1:1))
1×1 DataFrames.DataFrame
│ Row │ x1     │
│     │ String │
├─────┼────────┤
│ 1   │ data   │

```

Skipping comments by declaring what line the header starts on
```jldoctest
julia> using uCSV

julia> s =
       """
       # i am a comment
       I'm the header
       """;

julia> data, header = uCSV.read(IOBuffer(s), header=2);

julia> data
0-element Array{Any,1}

julia> header
1-element Array{String,1}:
 "I'm the header"

```

Skipping comments by declaring what commented lines start with and what line the header starts

!!! note

    Lines skipped because they are blank/empty or via `comment="..."` are not counted towards the row number used for locating `header=#`. For example, if the first 5 lines of your file are blank, and the next 5 are comments, you would still set `header=1` to the row that is on the 11-th line of the input source as the header.

```jldoctest
julia> using uCSV

julia> s =
       """
       # i am a comment
       I'm the header
       """;

julia> data, header = uCSV.read(IOBuffer(s), comment='#', header=1);

julia> data
0-element Array{Any,1}

julia> header
1-element Array{String,1}:
 "I'm the header"

```

Skipping comments, declaring the header row, and skipping some data
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       # i am a comment
       I'm the header
       skipped data
       included data
       """;

julia> DataFrame(uCSV.read(IOBuffer(s), comment='#', header=1, skiprows=1:1))
1×1 DataFrames.DataFrame
│ Row │ I'm the header │
│     │ String         │
├─────┼────────────────┤
│ 1   │ included data  │

```

```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       # i am a comment
       I'm the header
       skipped data
       included data
       """;

julia> DataFrame(uCSV.read(IOBuffer(s), skiprows=1:3))
1×1 DataFrames.DataFrame
│ Row │ x1            │
│     │ String        │
├─────┼───────────────┤
│ 1   │ included data │

```

!!! note

    Lines skipped via `skiprows` do not count towards the number of lines used for detecting column-types with `typedetectrows`
