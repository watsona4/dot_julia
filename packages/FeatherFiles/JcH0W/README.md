# FeatherFiles

[![Project Status: Active - The project has reached a stable, usable state and is being actively developed.](http://www.repostatus.org/badges/latest/active.svg)](http://www.repostatus.org/#active)
[![Build Status](https://travis-ci.org/queryverse/FeatherFiles.jl.svg?branch=master)](https://travis-ci.org/queryverse/FeatherFiles.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/8dbkg1vnew2pihtr/branch/master?svg=true)](https://ci.appveyor.com/project/queryverse/featherfiles-jl/branch/master)
[![FeatherFiles](http://pkg.julialang.org/badges/FeatherFiles_0.6.svg)](http://pkg.julialang.org/?pkg=FeatherFiles)
[![codecov.io](http://codecov.io/github/queryverse/FeatherFiles.jl/coverage.svg?branch=master)](http://codecov.io/github/queryverse/FeatherFiles.jl?branch=master)

## Overview

This package provides load and save support for [Feather files](https://github.com/wesm/feather) under the [FileIO.jl](https://github.com/JuliaIO/FileIO.jl) package.

## Installation

Use Pkg.add("FeatherFiles") in Julia to install FeatherFiles and its dependencies.

## Usage

### Load a feather file

To read a feather file into a ``DataFrame``, use the following julia code:

````julia
using FeatherFiles, DataFrames

df = DataFrame(load("data.feather"))
````

The call to ``load`` returns a ``struct`` that is an [IterableTable.jl](https://github.com/queryverse/IterableTables.jl), so it can be passed to any function that can handle iterable tables, i.e. all the sinks in [IterableTable.jl](https://github.com/queryverse/IterableTables.jl). Here are some examples of materializing a feather file into data structures that are not a ``DataFrame``:

````julia
using FeatherFiles, DataTables, IndexedTables, TimeSeries, Temporal, Gadfly

# Load into a DataTable
dt = DataTable(load("data.feather"))

# Load into an IndexedTable
it = IndexedTable(load("data.feather"))

# Load into a TimeArray
ta = TimeArray(load("data.feather"))

# Load into a TS
ts = TS(load("data.feather"))

# Plot directly with Gadfly
plot(load("data.feather"), x=:a, y=:b, Geom.line)
````

### Save a feather file

The following code saves any iterable table as a feather file:
````julia
using FeatherFiles

save("output.feather", it)
````
This will work as long as ``it`` is any of the types supported as sources in [IterableTables.jl](https://github.com/queryverse/IterableTables.jl).

### Using the pipe syntax

Both ``load`` and ``save`` also support the pipe syntax. For example, to load a feather file into a ``DataFrame``, one can use the following code:

````julia
using FeatherFiles, DataFrame

df = load("data.feather") |> DataFrame
````

To save an iterable table, one can use the following form:

````julia
using FeatherFiles, DataFrame

df = # Aquire a DataFrame somehow

df |> save("output.feather")
````

The pipe syntax is especially useful when combining it with [Query.jl](https://github.com/queryverse/Query.jl) queries, for example one can easily load a feather file, pipe it into a query, then pipe it to the ``save`` function to store the results in a new file.
