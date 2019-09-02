# ItemGraphs

*Shortest paths between items*

[![Build Status Unix][travis-badge]][travis-url] [![Build Status Windows][av-badge]][av-url] [![Coveralls][coveralls-badge]][coveralls-url] [![Codecov][codecov-badge]][codecov-url] [![Docs Stable][docs-badge-stable]][docs-url-stable] [![Docs Latest][docs-badge-dev]][docs-url-dev]

**ItemGraphs** is a simple wrapper around [LightGraphs](https://github.com/JuliaGraphs/LightGraphs.jl) that
enables my most common use case for graph-like data structures:
I have a collection of items that are in relations between each other and I want to get the shortest path
between two items.
That's it!

## Installation

The package can be installed through Julia's package manager:

```julia
julia> import Pkg; Pkg.add("ItemGraphs")
```

## Quickstart

```julia
# Create an ItemGraph that has integers as vertices
g = ItemGraph{Int}()

# Add some vertices
add_vertex!(g, 101)
add_vertex!(g, 202)

# Add some edges. If the vertices do not exists, they will be added as well
add_edge!(g, 101, 202)
add_edge!(g, 202, 303)
add_edge!(g, 202, 404)

# Get the shortest path, returns [101, 202, 404]
items(g, 101, 404)

# Create an ItemGraph that has integers as vertices and floats as edges
g = ItemGraph{Int, Float64}()
add_edge!(g, 101, 202, 1.0)
add_edge!(g, 202, 303, 2.0)
add_edge!(g, 202, 404) # The item assigned to the edge will be zero by default

# Get all items on the edges between 101 and 404, returns [1.0, 0.0]
edgeitems(g, 101, 404)
```

## Documentation

Please refer to the [documentation][docs-url-stable] for additional
information.

[travis-badge]: https://travis-ci.org/helgee/ItemGraphs.jl.svg?branch=master
[travis-url]: https://travis-ci.org/helgee/ItemGraphs.jl
[av-badge]: https://ci.appveyor.com/api/projects/status/b6lb3lgtxeg2fr51?svg=true
[av-url]: https://ci.appveyor.com/project/helgee/itemgraphs-jl
[coveralls-badge]: https://coveralls.io/repos/github/helgee/ItemGraphs.jl/badge.svg?branch=master
[coveralls-url]: https://coveralls.io/github/helgee/ItemGraphs.jl?branch=master
[codecov-badge]: http://codecov.io/github/helgee/ItemGraphs.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/helgee/ItemGraphs.jl?branch=master
[docs-badge-dev]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-url-dev]: https://helgee.github.io/ItemGraphs.jl/dev/
[docs-badge-stable]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-url-stable]: https://helgee.github.io/ItemGraphs.jl/stable/
