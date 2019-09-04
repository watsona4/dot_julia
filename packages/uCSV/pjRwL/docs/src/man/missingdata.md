# Missing Data

Missing data is very common in many fields of research, but not *ALL* fields of research. In addition, users may want to handle different encodings for missing data differently, e.g. encoding data that has been masked/removed for privacy reasons with a different value than data that simply doesn't exist. To enable these distinctions, uCSV requires that users provide arguments that instruct `uCSV.read` how they would like missing data to be parsed. The two easiest ways to achieve this are with the `typedetectrows` and `allowmissing` arguments. If `typedetectrows > 1` and both `missing` and some non-`missing` type `T` values are encountered in the column, `uCSV.read` will return that column as `Union{T, Missing}`. For instances where the first missing value is encountered many hundreds of lines down the dataset, it is advised that you declare which columns may contain missing values with the `allowmissing` argument for improved parsing efficiency. Users may also use the `types` argument to specify a column as being `Union{T, Missing}`.

Detecting columns that contain missing values via `typedetectrows`
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       1,hey,1
       2,you,2
       3,,3
       4,"",4
       5,NULL,5
       6,NA,6
       """;

julia> encodings = Dict("" => missing, "\"\"" => missing, "NULL" => missing, "NA" => missing);

julia> DataFrame(uCSV.read(IOBuffer(s), encodings=encodings, typedetectrows=3))
6×3 DataFrames.DataFrame
│ Row │ x1    │ x2      │ x3    │
│     │ Int64 │ String⍰ │ Int64 │
├─────┼───────┼─────────┼───────┤
│ 1   │ 1     │ hey     │ 1     │
│ 2   │ 2     │ you     │ 2     │
│ 3   │ 3     │ missing │ 3     │
│ 4   │ 4     │ missing │ 4     │
│ 5   │ 5     │ missing │ 5     │
│ 6   │ 6     │ missing │ 6     │

```

Declaring that all columns may contain missing values
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       1,hey,1
       2,you,2
       3,,3
       4,"",4
       5,NULL,5
       6,NA,6
       """;

julia> encodings = Dict("" => missing, "\"\"" => missing, "NULL" => missing, "NA" => missing);

julia> DataFrame(uCSV.read(IOBuffer(s), encodings=encodings, allowmissing=true))
6×3 DataFrames.DataFrame
│ Row │ x1     │ x2      │ x3     │
│     │ Int64⍰ │ String⍰ │ Int64⍰ │
├─────┼────────┼─────────┼────────┤
│ 1   │ 1      │ hey     │ 1      │
│ 2   │ 2      │ you     │ 2      │
│ 3   │ 3      │ missing │ 3      │
│ 4   │ 4      │ missing │ 4      │
│ 5   │ 5      │ missing │ 5      │
│ 6   │ 6      │ missing │ 6      │

```

Declaring whether each column may contain missing values with a boolean vector
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       1,hey,1
       2,you,2
       3,,3
       4,"",4
       5,NULL,5
       6,NA,6
       """;

julia> encodings = Dict("" => missing, "\"\"" => missing, "NULL" => missing, "NA" => missing);

julia> DataFrame(uCSV.read(IOBuffer(s), encodings=encodings, allowmissing=[false, true, false]))
6×3 DataFrames.DataFrame
│ Row │ x1    │ x2      │ x3    │
│     │ Int64 │ String⍰ │ Int64 │
├─────┼───────┼─────────┼───────┤
│ 1   │ 1     │ hey     │ 1     │
│ 2   │ 2     │ you     │ 2     │
│ 3   │ 3     │ missing │ 3     │
│ 4   │ 4     │ missing │ 4     │
│ 5   │ 5     │ missing │ 5     │
│ 6   │ 6     │ missing │ 6     │

```

Declaring the missingability of a subset of columns with a Dictionary (keys are column indices)
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       1,hey,1
       2,you,2
       3,,3
       4,"",4
       5,NULL,5
       6,NA,6
       """;

julia> encodings = Dict("" => missing, "\"\"" => missing, "NULL" => missing, "NA" => missing);

julia> DataFrame(uCSV.read(IOBuffer(s), encodings=encodings, allowmissing=Dict(2 => true)))
6×3 DataFrames.DataFrame
│ Row │ x1    │ x2      │ x3    │
│     │ Int64 │ String⍰ │ Int64 │
├─────┼───────┼─────────┼───────┤
│ 1   │ 1     │ hey     │ 1     │
│ 2   │ 2     │ you     │ 2     │
│ 3   │ 3     │ missing │ 3     │
│ 4   │ 4     │ missing │ 4     │
│ 5   │ 5     │ missing │ 5     │
│ 6   │ 6     │ missing │ 6     │

```

Declaring the missingability of a subset of columns with a Dictionary (keys are column names)
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       a,b,c
       1,hey,1
       2,you,2
       3,,3
       4,"",4
       5,NULL,5
       6,NA,6
       """;

julia> encodings = Dict("" => missing, "\"\"" => missing, "NULL" => missing, "NA" => missing);

julia> DataFrame(uCSV.read(IOBuffer(s), encodings=encodings, header=1, allowmissing=Dict("b" => true)))
6×3 DataFrames.DataFrame
│ Row │ a     │ b       │ c     │
│     │ Int64 │ String⍰ │ Int64 │
├─────┼───────┼─────────┼───────┤
│ 1   │ 1     │ hey     │ 1     │
│ 2   │ 2     │ you     │ 2     │
│ 3   │ 3     │ missing │ 3     │
│ 4   │ 4     │ missing │ 4     │
│ 5   │ 5     │ missing │ 5     │
│ 6   │ 6     │ missing │ 6     │

```

Declaring the missingability of a subset of columns by specifying the element-type
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       1,hey,1
       2,you,2
       3,,3
       4,"",4
       5,NULL,5
       6,NA,6
       """;

julia> encodings = Dict("" => missing, "\"\"" => missing, "NULL" => missing, "NA" => missing);

julia> DataFrame(uCSV.read(IOBuffer(s), encodings=encodings, types=Dict(2 => Union{String, Missing})))
6×3 DataFrames.DataFrame
│ Row │ x1    │ x2      │ x3    │
│     │ Int64 │ String⍰ │ Int64 │
├─────┼───────┼─────────┼───────┤
│ 1   │ 1     │ hey     │ 1     │
│ 2   │ 2     │ you     │ 2     │
│ 3   │ 3     │ missing │ 3     │
│ 4   │ 4     │ missing │ 4     │
│ 5   │ 5     │ missing │ 5     │
│ 6   │ 6     │ missing │ 6     │

```
