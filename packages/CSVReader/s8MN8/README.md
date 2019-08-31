# CSVReader

[![Build Status](https://travis-ci.org/tk3369/CSVReader.jl.svg?branch=master)](https://travis-ci.org/tk3369/CSVReader.jl)
[![codecov](https://codecov.io/gh/tk3369/CSVReader.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/tk3369/CSVReader.jl)
[![Coverage Status](https://coveralls.io/repos/github/tk3369/CSVReader.jl/badge.svg?branch=master)](https://coveralls.io/github/tk3369/CSVReader.jl?branch=master)

This is a simple CSV reader that performs well and is easy to use.
It does not have any bells and whistles.
It should work fine if the file is well formatted and free of errors.

Check out [CSV.jl](https://github.com/JuliaData/CSV.jl) if you need more features
and better performance for large files.

Requires Julia 1.0.

## Installation

`] add https://github.com/tk3369/CSVReader.jl`

## Manual

### Basic Usage

```
shell> ls -l random_1000_1000.csv
-rw-r--r--  1 tomkwong  staff  19277409 Sep 15 09:42 random_1000_1000.csv

jjulia> @btime CSVReader.read_csv("/Users/tomkwong/Downloads/random_1000_1000.csv");
  1.162 s (11084440 allocations: 354.86 MiB)
```

By default, the reader tries to infer column types by looking at the first row.  Of course, that's not
very accurate if you have any missing data or mixed number/string columns.  For now, it may be easier 
to just specify the column parsers.

### Specify Your Own Column Types 

There are few predefined parsers, represented as "f", "s", or "i".  
You can use the `parsers` literal string to create an array of parsers.
Optionally, the parser spec takes a number for each parser as in `parsers"f:10"`.
```
julia> parsers"f,s,i,f:2"
5-element Array{Any,1}:
 CSVReader.parse_float64
 CSVReader.parse_string 
 CSVReader.parse_int    
 CSVReader.parse_float64
 CSVReader.parse_float64    
```

So how do you use it?
```
julia> df = CSVReader.read_csv("FL_insurance_sample.csv", parsers"i,s:2,f:11,s:2,i");

julia> describe(df)
18×8 DataFrame
│ Row │ variable           │ mean      │ min            │ median    │ max               │ nunique │ nmissing │ eltype  │
├─────┼────────────────────┼───────────┼────────────────┼───────────┼───────────────────┼─────────┼──────────┼─────────┤
│ 1   │ policyID           │ 5.48662e5 │ 100074         │ 548525.0  │ 999971            │         │ 0        │ Int64   │
│ 2   │ statecode          │           │ FL             │           │ FL                │ 1       │ 0        │ String  │
│ 3   │ county             │           │ ALACHUA COUNTY │           │ WASHINGTON COUNTY │ 67      │ 0        │ String  │
│ 4   │ eq_site_limit      │ 731478.0  │ 0.0            │ 0.0       │ 2.16e9            │         │ 0        │ Float64 │
│ 5   │ hu_site_limit      │ 2.07435e6 │ 0.0            │ 1.92691e5 │ 2.16e9            │         │ 0        │ Float64 │
│ 6   │ fl_site_limit      │ 6.64601e5 │ 0.0            │ 0.0       │ 2.16e9            │         │ 0        │ Float64 │
│ 7   │ fr_site_limit      │ 9.91172e5 │ 0.0            │ 0.0       │ 2.16e9            │         │ 0        │ Float64 │
│ 8   │ tiv_2011           │ 2.17288e6 │ 90.0           │ 2.02105e5 │ 2.16e9            │         │ 0        │ Float64 │
│ 9   │ tiv_2012           │ 2.571e6   │ 73.37          │ 241631.0  │ 1.701e9           │         │ 0        │ Float64 │
│ 10  │ eq_site_deductible │ 778.791   │ 0.0            │ 0.0       │ 6.27377e6         │         │ 0        │ Float64 │
│ 11  │ hu_site_deductible │ 7037.98   │ 0.0            │ 0.0       │ 7.38e6            │         │ 0        │ Float64 │
│ 12  │ fl_site_deductible │ 192.453   │ 0.0            │ 0.0       │ 450000.0          │         │ 0        │ Float64 │
│ 13  │ fr_site_deductible │ 26.4836   │ 0.0            │ 0.0       │ 900000.0          │         │ 0        │ Float64 │
│ 14  │ point_latitude     │ 28.0875   │ 24.5475        │ 28.0571   │ 30.9898           │         │ 0        │ Float64 │
│ 15  │ point_longitude    │ -81.9036  │ -87.4473       │ -81.5857  │ -80.0333          │         │ 0        │ Float64 │
│ 16  │ line               │           │ Commercial     │           │ Residential       │ 2       │ 0        │ String  │
│ 17  │ construction       │           │ Masonry        │           │ Wood              │ 5       │ 0        │ String  │
│ 18  │ point_granularity  │ 1.64091   │ 1              │ 1.0       │ 7                 │         │ 0        │ Int64   │
```

## To-Do

- [x] Handle quoted numeric cells that contains comma separator
- [x] Add unit tests
- [ ] Support reading data into vector of named tuples and implement Tables.jl
- [ ] Multi-threading for reading large files
- [ ] Infer column types by reading more rows

