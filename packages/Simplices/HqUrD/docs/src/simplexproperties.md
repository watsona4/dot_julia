# Simplex properties

Given a simplex, the following functions calculate useful quantities.

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
