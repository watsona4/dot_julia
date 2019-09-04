# Reading Data from URLs

Using the [HTTP.jl](https://github.com/JuliaWeb/HTTP.jl) package
```
julia> using uCSV, DataFrames, HTTP

julia> html = "https://raw.github.com/vincentarelbundock/Rdatasets/master/csv/datasets/USPersonalExpenditure.csv";

julia> DataFrame(uCSV.read(IOBuffer(HTTP.get(html).body), quotes='"', header=1))
5×6 DataFrames.DataFrame
│ Row │                     │ 1940    │ 1945    │ 1950    │ 1955    │ 1960    │
│     │ String              │ Float64 │ Float64 │ Float64 │ Float64 │ Float64 │
├─────┼─────────────────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ 1   │ Food and Tobacco    │ 22.2    │ 44.5    │ 59.6    │ 73.2    │ 86.8    │
│ 2   │ Household Operation │ 10.5    │ 15.5    │ 29.0    │ 36.5    │ 46.2    │
│ 3   │ Medical and Health  │ 3.53    │ 5.76    │ 9.71    │ 14.0    │ 21.1    │
│ 4   │ Personal Care       │ 1.04    │ 1.98    │ 2.45    │ 3.4     │ 5.4     │
│ 5   │ Private Education   │ 0.341   │ 0.974   │ 1.8     │ 2.6     │ 3.64    │

```
