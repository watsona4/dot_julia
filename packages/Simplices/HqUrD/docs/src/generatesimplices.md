
## Generation of (non)intersecting simplices/points


### Points inside/outside a simplex
Given a simplex, the following points can generate a point or simplices that lies either in the interior or outside that simplex.

```@docs
insidepoints(npts::Int, parentsimplex::Array{T, 2}) where {T<:Number}
```

```@docs
outsidepoint(parentsimplex::Array{T, 2}) where {T<:Number}
```

```@docs
outsidepoints(npts::Int, parentsimplex::Array{T, 2}) where {T<:Number}
```

```@docs
childsimplex(parentsimplex::Array{T, 2}) where {T<:Number}
```

### Generating simplices that intersect

There are many ways simplices possibly can intersect, but they all boil down
to three cases: 1) there is no intersection, 2) they intersect along a common vertex or boundary, or 3) the intersection is more complex. The following functions generate simplices that either share at least one vertex, or simplices that intersect in nontrivial ways (i.e. intersection is not along a vertex or an edge).

```@docs
simplices_sharing_vertices(dim::Int)
```

```@docs
nontrivially_intersecting_simplices(dim::Int)
```
