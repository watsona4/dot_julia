# Quotes and Escapes

## Quoted Fields

Quotes are not interpreted by default
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       "I,have,delimiters,in,my,field"
       """;

julia> DataFrame(uCSV.read(IOBuffer(s)))
1×6 DataFrames.DataFrame
│ Row │ x1     │ x2     │ x3         │ x4     │ x5     │ x6     │
│     │ String │ String │ String     │ String │ String │ String │
├─────┼────────┼────────┼────────────┼────────┼────────┼────────┤
│ 1   │ "I     │ have   │ delimiters │ in     │ my     │ field" │

```

But you can declare the character that `uCSV.read` should interpret as a quote
```jldoctest
julia> using uCSV, DataFrames

julia> s =
       """
       "I,have,delimiters,in,my,field"
       """;

julia> DataFrame(uCSV.read(IOBuffer(s), quotes='"'))
1×1 DataFrames.DataFrame
│ Row │ x1                            │
│     │ String                        │
├─────┼───────────────────────────────┤
│ 1   │ I,have,delimiters,in,my,field │

```

## Quoted Fields w/ Internal Double Quotes

A common convention is to have double-quotes within quoted fields to represent text that should remain quoted after parsing.
```jldoctest
julia> using uCSV, DataFrames

julia> players = ["\"Rich \"\"Goose\"\" Gossage\"",
                  "\"Henry \"\"Hammerin' Hank\"\" Aaron\""];

julia> for p in players
           println(p)
       end
"Rich ""Goose"" Gossage"
"Henry ""Hammerin' Hank"" Aaron"

julia> DataFrame(uCSV.read(IOBuffer(join(players, '\n')), quotes='"', escape='"'))
2×1 DataFrames.DataFrame
│ Row │ x1                           │
│     │ String                       │
├─────┼──────────────────────────────┤
│ 1   │ Rich "Goose" Gossage         │
│ 2   │ Henry "Hammerin' Hank" Aaron │

```

## Escapes

Special characters that would normally be parsed as quotes, newlines, or delimiters can be escaped
```jldoctest
julia> using uCSV, DataFrames

julia> players = ["\"Rich \\\"Goose\\\" Gossage\"",
                  "\"Henry \\\"Hammerin' Hank\\\" Aaron\""];

julia> for p in players
           println(p)
       end
"Rich \"Goose\" Gossage"
"Henry \"Hammerin' Hank\" Aaron"

julia> DataFrame(uCSV.read(IOBuffer(join(players, '\n')), quotes='"', escape='\\'))
2×1 DataFrames.DataFrame
│ Row │ x1                           │
│     │ String                       │
├─────┼──────────────────────────────┤
│ 1   │ Rich "Goose" Gossage         │
│ 2   │ Henry "Hammerin' Hank" Aaron │

```
