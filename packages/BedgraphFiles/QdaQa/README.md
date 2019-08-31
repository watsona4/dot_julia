# BedgraphFiles.jl

[![Project Status: Active - The project has reached a stable, usable state and is being actively developed.](http://www.repostatus.org/badges/latest/active.svg)](http://www.repostatus.org/#active)
[![Build Status](https://travis-ci.org/CiaranOMara/BedgraphFiles.jl.svg?branch=master)](https://travis-ci.org/CiaranOMara/BedgraphFiles.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/jny2ep4u3cmly8pj/branch/master?svg=true)](https://ci.appveyor.com/project/CiaranOMara/Bedgraphfiles-jl/branch/master)
[![codecov.io](http://codecov.io/github/CiaranOMara/BedgraphFiles.jl/coverage.svg?branch=master)](http://codecov.io/github/CiaranOMara/BedgraphFiles.jl?branch=master)
[![Coverage Status](https://coveralls.io/repos/github/CiaranOMara/BedgraphFiles.jl/badge.svg?branch=master)](https://coveralls.io/github/CiaranOMara/BedgraphFiles.jl?branch=master)

## Overview

This package provides load and save support for [Bedgraph](https://github.com/CiaranOMara/Bedgraph.jl)
under the [FileIO](https://github.com/JuliaIO/FileIO.jl) package, and also implements the [IterableTables](https://github.com/davidanthoff/IterableTables.jl) interface for easy conversion between tabular data structures.

## Installation
You can install BedgraphFiles from the Julia REPL:
```julia
using Pkg
add("BedgraphFiles")
#Pkg.add("BedgraphFiles") for julia prior to v 0.7
```

## Usage

### Loading bedGraph files

To load a bedGraph file into a ``Vector{Bedgraph.Record}``, use the following Julia code:
````julia
using FileIO, BedgraphFiles, Bedgraph

records = Vector{Bedgraph.Record}(load("data.bedgraph"))
````

### Saving bedGraph files

> **Note:** saving on top of an existing file will overwrite metadata/header information with a minimal working header.

The following example saves a ``Vector{Bedgraph.Record}`` to a bedGraph file:
````julia
using FileIO, BedgraphFiles, Bedgraph

records = [Bedgraph.Record("chr", i, i + 99, rand()) for i in 1:100:1000]

save("output.bedgraph", records)
````

### IterableTables
The execution of ``load`` returns a ``struct`` that adheres to the [IterableTables](https://github.com/davidanthoff/IterableTables.jl) interface, and can be passed to any function that also implements the interface, i.e. all the sinks in [IterableTable.jl](https://github.com/davidanthoff/IterableTables.jl).

The following code shows an example of loading a bedGraph file into a [DataFrame](https://github.com/JuliaData/DataFrames.jl):
```julia
using FileIO, BedgraphFiles, DataFrames

df = DataFrame(load("data.bedgraph"))
```

Here are some more examples of materialising a bedGraph file into other data structures:
```julia
using FileIO, BedgraphFiles, DataTables, IndexedTables, Gadfly

# Load into a DataTable
dt = DataTable(load("data.bedgraph"))

# Load into an IndexedTable
it = IndexedTable(load("data.bedgraph"))

# Plot directly with Gadfly
plot(load("data.bedgraph"), xmin=:leftposition, xmax=:rightposition, y=:value, Geom.bar)
```

The following code saves any compatible source to a bedGraph file:
```julia
using FileIO, BedgraphFiles

it = getiterator(data)

save("output.bedgraph", it)
```

### Using the pipe syntax

Both `load` and `save` also support the pipe syntax. For example, to load a bedGraph file into a `DataFrame`, one can use the following code:
```julia
using FileIO, BedgraphFiles, DataFrame

df = load("data.bedgraph") |> DataFrame
```

To save an iterable table, one can use the following form:
```julia
using FileIO, BedgraphFiles, DataFrame

df = # Aquire a DataFrame somehow.

df |> save("output.bedgraph")
```

The `save` method returns the data provided or `Vector{Bedgraph.Record}`. This is useful when periodically saving your work during a sequence of operations.
```julia
records = some sequence of operations |> save("output.bedgraph")
```

The pipe syntax is especially useful when combining it with [Query.jl](https://github.com/davidanthoff/Query.jl) queries. For example, one can easily load a bedGraph file, pipe its data into a query, and then store the query result by piping it to the `save` function.
```julia
using FileIO, BedgraphFiles, Query
load("data.bedgraph") |> @filter(_.chrom == "chr19") |> save("data-chr19.bedgraph")
```
## Acknowledgements
This package is largely -- if not completely -- inspired by the work of [David Anthoff](https://github.com/davidanthoff). Other influences are from the [BioJulia](https://github.com/BioJulia) community.
