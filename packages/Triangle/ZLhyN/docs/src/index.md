# Triangle.jl Documentation

A Julia interface to Jonathan Richard Shewchuk [Triangle](https://www.cs.cmu.edu/~quake/triangle.html).

The library builds the C version and then expose methods to calculate CDTs.

## Functions

```@docs
basic_triangulation_vertices(vertices::Array{Float64,2})
```

```@docs
basic_triangulation(vertices::Array{Float64,2},vertices_map::Array{Int64,1})
```

```@docs
basic_triangulation_vertices(vertices::Array{Float64,2},vertices_map::Array{Int64,1})
```

```@docs
constrained_triangulation(vertices::Array{Float64,2}, vertices_map::Array{Int64,1}, edges_list::Array{Int64,2})
```

```@docs
constrained_triangulation_vertices(vertices::Array{Float64,2}, vertices_map::Array{Int64,1}, edges_list::Array{Int64,2})
```

```@docs
constrained_triangulation(vertices::Array{Float64,2}, vertices_map::Array{Int64,1}, edges_list::Array{Int64,2}, edges_boundary::Array{Bool,1})
```

```@docs
constrained_triangulation_vertices(vertices::Array{Float64,2}, vertices_map::Array{Int64,1}, edges_list::Array{Int64,2}, edges_boundary::Array{Bool,1})
```

## Index

```@index
```