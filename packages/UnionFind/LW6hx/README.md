UnionFind.jl
============

`UnionFind.jl` is a light-weight library for identifying groups of nodes in
undirected graphs. It is written in [Julia 0.7](http://julialang.org/). It is
currently in version 0.1.0.

# API

This library exports two types, `UnionFinder`, and `CompressedFinder`.

## UnionFinder

`UnionFinder{T <: Integer}` is a graph representation which allows for the 
dynamic addition of edges as well as the identification of groups.

### Constructors

*  `UnionFinder{T <: Integer}(nodes :: T) :: UnionFinder{T}` returns a
   `UnionFinder` instance representing a graph of `nodes` unconnected nodes.
   Each node will be indexed by a unique integer of type `T` in the inclusive
   range [`1`, `nodes`]. If `nodes` is non-positive, an `ArgumentError` will
   be thrown.

### Methods

The identification of groups is handled lazily, meaning that all non-trivial
methods will modify the contents of the target `UnionFinder` instance.

*  `union!{T <: Integer}(uf :: UnionFinder{T}, u :: T, v :: T)` adds an edge
   to `uf` connecting node `u` to node `v`. If either `u` or `v` is
   non-positive or greater than `nodes`, a `BoundsError` will be thrown.
*  `union!{T <: Integer}(uf :: UnionFinder{T}, edges :: Array{(T, T)})` adds
   each edges within `edges` to `uf`. This method obeys the same bounds
   restrictions as the single edge `union!` method.
*  `union!{T <: Integer}(uf :: UnionFinder{T}, us :: Array{T}, vs :: Array{T})`
   adds edges of the form (`us[i]`, `vs[i]`) to `uf`. This method obeys the
   same bounds restrictions as the single edge `union!` method.
*  `find!{T <: Integer}(uf :: UnionFinder{T}, node :: T) :: T` returns the
   unique id of the node group containing `node`.
*  `size!{T <: Integer}(uf :: UnionFinder{T}, node :: T) :: T` returns the
   number of nodes in the group containing `node`.
*  `reset!(uf :: UnionFinder)` disconnects all nodes within `uf`, allowing for
   a new set of edges to be analyzed without making further allocations.
*  `length(uf :: UnionFinder) :: Int` returns the number of nodes within `uf`.

### Fields

The fields of `UnionFinder` instances should not be accesed by user-level code.

## CompressedFinder

`CompressedFinder{T <: Integer}`

### Constructors

*  `CompressedFinder{T <: Integer}(uf :: UnionFinder) :: CompressedFinder{T}`
   returns a `CompressedFinder` instance corresponding to the same groups
   represented by 

### Methods

*  `find{T <: Integer}(cf :: CompressedFinder{T}, node :: T) :: T` returns the
   unique id of the group containing `node`. If `node` is non-positive or
   is larger than the number of nodes in `cf`, a `BoundsError` is thrown.
*  `groups{T <: Integer}(cf :: CompressedFinder{T}) :: T` returns the number
   of groups within `cf`.

### Fields

*  `ids :: Array{T}` is an array mapping node indices to the group which
   contains them.
*  `groups :: T` is the number of groups in the `CompressedFinder` instance.

# Examples

## Floodfill

```julia
using UnionFind

function floodfill(grid, wrap=false)
    uf = UnionFinder(length(grid))

    height, width = size(grid)
    for x in 1:width
        for y in 1:height
            # Look rightwards.
            if x != width && grid[x, y] == grid[x + 1, y]
                union!(uf, flatten(x, y, grid), flatten(x + 1, y, grid))
            elseif wrap && grid[x, y] == grid[1, y]
                union!(uf, flatten(x, y, grid), flatten(1, y, grid))
            end

            # Look upwards.
            if y != height && grid[x, y] == grid[x, y + 1]
                union!(uf, flatten(x, y, grid), flatten(x, y + 1, grid))
            elseif wrap && grid[x, y] == grid[x, 1]
                union!(uf, flatten(x, y, grid), flatten(x, 1, grid))
            end
        end
    end

    cf = CompressedFinder(uf)
    return reshape(cf.ids, size(grid))
end

flatten(x, y, grid) = y + (x - 1)size(grid)[1]
```

## Kruskal

```julia
using UnionFind

# edges must be pre-sorted according to weight.
function kruskal{T <: Integer}(nodes :: T, edges :: Array{(T, T)})
    uf = UnionFinder(nodes)
    mst = Array{(T, T)}

    for i in 1:length(edges)
        (u, v) = edges[i]
        if find!(uf, u) != find!(uf, v)
            union!(uf, u, v)
            push!(mst, (u, v))
        end
    end
end
```
