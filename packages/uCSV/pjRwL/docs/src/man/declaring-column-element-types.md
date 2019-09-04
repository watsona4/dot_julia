# Declaring Column Element Types

## Booleans

If booleans are encoded as lower-case `true` and `false` in your dataset, the default parse function for booleans can be used. You can request this by setting the `type` argument.

Declaring all columns to be boolean
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       true
       false
       """;

julia> DataFrame(uCSV.read(IOBuffer(s), types=Bool))
2×1 DataFrames.DataFrame
│ Row │ x1    │
│     │ Bool  │
├─────┼───────┤
│ 1   │ true  │
│ 2   │ false │

```

Declaring the type of each column with a vector
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       true
       false
       """;

julia> DataFrame(uCSV.read(IOBuffer(s), types=[Bool]))
2×1 DataFrames.DataFrame
│ Row │ x1    │
│     │ Bool  │
├─────┼───────┤
│ 1   │ true  │
│ 2   │ false │

```

Declaring the type of specific columns with a dictionary
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       true
       false
       """;

julia> DataFrame(uCSV.read(IOBuffer(s), types=Dict(1 => Bool)))
2×1 DataFrames.DataFrame
│ Row │ x1    │
│     │ Bool  │
├─────┼───────┤
│ 1   │ true  │
│ 2   │ false │

```

If the booleans in your dataset are encoding by anything other than `true` and `false`, you'll
need to use the `encodings` argument to map the `String => Bool` conversions.
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       T
       F
       True
       False
       0
       1
       yes
       no
       y
       n
       YES
       NO
       Yes
       No
       """;

julia> trues = Dict(s => true for s in ["T", "True", "1", "yes", "y", "YES", "Yes"])
Dict{String,Bool} with 7 entries:
  "YES"  => true
  "True" => true
  "1"    => true
  "yes"  => true
  "T"    => true
  "Yes"  => true
  "y"    => true

julia> falses = Dict(s => false for s in ["F", "False", "0", "no", "n", "NO", "No"])
Dict{String,Bool} with 7 entries:
  "NO"    => false
  "No"    => false
  "False" => false
  "0"     => false
  "no"    => false
  "F"     => false
  "n"     => false

julia> DataFrame(uCSV.read(IOBuffer(s), encodings=merge(trues, falses)))
14×1 DataFrames.DataFrame
│ Row │ x1    │
│     │ Bool  │
├─────┼───────┤
│ 1   │ true  │
│ 2   │ false │
│ 3   │ true  │
│ 4   │ false │
│ 5   │ false │
│ 6   │ true  │
│ 7   │ true  │
│ 8   │ false │
│ 9   │ true  │
│ 10  │ false │
│ 11  │ true  │
│ 12  │ false │
│ 13  │ true  │
│ 14  │ false │

```

## Symbols

Declaring all columns as Symbol
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       x1
       y7
       µ∆
       """;

julia> df = DataFrame(uCSV.read(IOBuffer(s), types=Symbol))
3×1 DataFrames.DataFrame
│ Row │ x1     │
│     │ Symbol │
├─────┼────────┤
│ 1   │ x1     │
│ 2   │ y7     │
│ 3   │ µ∆     │

julia> eltype.(DataFrames.columns(df)) == [Symbol]
true

```

Declaring the type of each column
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       x1
       y7
       µ∆
       """;

julia> df = DataFrame(uCSV.read(IOBuffer(s), types=[Symbol]))
3×1 DataFrames.DataFrame
│ Row │ x1     │
│     │ Symbol │
├─────┼────────┤
│ 1   │ x1     │
│ 2   │ y7     │
│ 3   │ µ∆     │

julia> eltype.(DataFrames.columns(df)) == [Symbol]
true

```

Declaring the type of specific columns
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       x1
       y7
       µ∆
       """;

julia> df = DataFrame(uCSV.read(IOBuffer(s), types=Dict(1 => Symbol)))
3×1 DataFrames.DataFrame
│ Row │ x1     │
│     │ Symbol │
├─────┼────────┤
│ 1   │ x1     │
│ 2   │ y7     │
│ 3   │ µ∆     │

julia> eltype.(DataFrames.columns(df)) == [Symbol]
true

```

## Dates

Dates that are parseable with the default formatting
```jldoctest
julia> using uCSV, DataFrames, Dates

julia> s =
       """
       2013-01-01
       """;

julia> DataFrame(uCSV.read(IOBuffer(s), types=Date))
1×1 DataFrames.DataFrame
│ Row │ x1         │
│     │ Dates.Date │
├─────┼────────────┤
│ 1   │ 2013-01-01 │

```

### Dates that require user-specified parsing rules

!!! note

    [Check out the full list of available formatting options for Dates/DateTimes in the Julia docs](https://docs.julialang.org/en/stable/stdlib/dates/#Base.Dates.DateFormat)

Specifying column types in conjunction with declaring a type-specific parser function
```jldoctest
julia> using uCSV, DataFrames, Dates

julia> s =
       """
       12/24/36
       """;

julia> DataFrame(uCSV.read(IOBuffer(s), types=Date, typeparsers=Dict(Date => x -> Date(x, "m/d/y"))))
1×1 DataFrames.DataFrame
│ Row │ x1         │
│     │ Dates.Date │
├─────┼────────────┤
│ 1   │ 0036-12-24 │

```

Specifying a column-specific parser function
```jldoctest
julia> using uCSV, DataFrames, Dates

julia> s =
       """
       12/24/36
       """;

julia> DataFrame(uCSV.read(IOBuffer(s), colparsers=Dict(1 => x -> Date(x, "m/d/y"))))
1×1 DataFrames.DataFrame
│ Row │ x1         │
│     │ Dates.Date │
├─────┼────────────┤
│ 1   │ 0036-12-24 │

```

## DateTimes

The same techniques demonstrated for other types also apply here.
```jldoctest
julia> using uCSV, DataFrames, Dates

julia> s =
       """
       2015-01-01 00:00:00
       2015-01-02 00:00:01
       2015-01-03 00:12:00.001
       """;

julia> function datetimeparser(x)
           if in('.', x)
              return DateTime(x, "y-m-d H:M:S.s")
          else
              return DateTime(x, "y-m-d H:M:S")
          end
       end
datetimeparser (generic function with 1 method)

julia> DataFrame(uCSV.read(IOBuffer(s), colparsers=(x -> datetimeparser(x))))
3×1 DataFrames.DataFrame
│ Row │ x1                      │
│     │ Dates.DateTime          │
├─────┼─────────────────────────┤
│ 1   │ 2015-01-01T00:00:00     │
│ 2   │ 2015-01-02T00:00:01     │
│ 3   │ 2015-01-03T00:12:00.001 │

```
