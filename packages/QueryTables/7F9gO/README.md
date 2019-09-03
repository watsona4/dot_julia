# QueryTables.jl

[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![Build Status](https://travis-ci.com/queryverse/QueryTables.jl.svg?branch=master)](https://travis-ci.com/queryverse/QueryTables.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/nxtbjw982bd7bby6/branch/master?svg=true)](https://ci.appveyor.com/project/queryverse/querytables-jl/branch/master)
[![codecov](https://codecov.io/gh/queryverse/QueryTables.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/queryverse/QueryTables.jl)

## Overview

A simple read-only table type for the [Queryverse](https://github.com/queryverse).

## Installation

You can install the package at the Pkg REPL-mode with:

```julia
pkg> add QueryTables
```

## Getting started

The main type in this package is `DataTable`, a data structure for tabular data. To create a new `DataTable` with a number of columns, just pass the columns as keyword arguments to the `DataTable` constructor:

```julia
julia> dt = DataTable(Name=["John", "Sally", "Jim"], Age=[23., 43., 56.], Children=[2, 0, 3])
3x3 DataTable
Name  │ Age  │ Children
──────┼──────┼─────────
John  │ 23.0 │ 2
Sally │ 43.0 │ 0
Jim   │ 56.0 │ 3
```

To access an individual column by name, use the `.` dot syntax:

```julia
julia> dt.Age
3-element Array{Float64,1}:
 23.0
 43.0
 56.0
```

To access an individual row, use the normal julia index syntax:

```julia
julia> dt[2]
(Name = "Sally", Age = 43.0, Children = 0)
```

If you want to access the value in an individual cell, it is generally more efficient to first access the column via the dot syntax, and then select the value for a given row via indexing:

```julia
julia> dt.Name[2]
"Sally"
```

You can also create a new `DataTable` by passing any object to its constructor that implements the [TableTraits.jl](https://github.com/queryverse/TableTraits.jl) interface. That includes everything in the [Queryverse](https://www.queryverse.org/), but also many other table types like [DataFrames.jl](https://github.com/JuliaData/DataFrames.jl), [IndexedTables.jl](https://github.com/JuliaComputing/IndexedTables.jl) etc. Every `DataTable` also implements the [TableTraits.jl](https://github.com/queryverse/TableTraits.jl) interface and can therefore be passed to any function that accepts a [TableTraits.jl](https://github.com/queryverse/TableTraits.jl) value.

## Alternatives

QueryTables.jl is not the only julia initiative for tabular data, there are many other packages that have similar goals. Take a look at [DataFrames.jl](https://github.com/JuliaData/DataFrames.jl), [IndexedTables.jl](https://github.com/JuliaComputing/IndexedTables.jl) and [TypedTables.jl](https://github.com/FugroRoames/TypedTables.jl) (which in particular was a major inspiration for this package here). If I missed other packages, please let me know and I'll add them to this list!

## Getting help

Please ask any usage question in the [Data Domain](https://discourse.julialang.org/c/domain/data) on the [julia Discourse forum](https://discourse.julialang.org/). If you find a bug or have an improvement suggestion for this package, please open an issue in this github repository.
