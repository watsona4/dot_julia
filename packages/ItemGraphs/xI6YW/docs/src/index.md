# ItemGraphs

*Shortest paths between items*

**ItemGraphs** is a simple wrapper around [LightGraphs](https://github.com/JuliaGraphs/LightGraphs.jl) that enables my most common use case for graph-like data structures:
I have a collection of items that are in relations between each other and I want to get the shortest path between two items. That's it!

## Installation

The package can be installed through Julia's package manager:

```julia
Pkg.add("ItemGraphs")
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
getpath(g, 101, 404)
```
