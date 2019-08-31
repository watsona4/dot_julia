# Function reference


## Intersection

```@docs
simplexintersection(S1::Array{Float64, 2}, S2::Array{Float64, 2};
		tolerance::Float64 = 1/10^10)
```

## Generate (non)intersecting simplices/points

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

```@docs
simplices_sharing_vertices(dim::Int)
```

```@docs
nontrivially_intersecting_simplices(dim::Int)
```

## Properties of simplices


```@docs
orientation(simplex::Array{T, 2}) where {T<:Number}
```

```@docs
volume(simplex::Array{T, 2}) where {T<:Number}
```

```@docs
radius(simplex::Array{T, 2}) where {T<:Number}
```

```@docs
radius(simplex::Array{T, 2}, centroid::Array{T, 2}) where {T<:Number}
```

```@docs
centroid(simplex::Array{T, 2}) where {T<:Number}
```
