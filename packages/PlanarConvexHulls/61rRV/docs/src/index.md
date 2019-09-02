# PlanarConvexHulls.jl

PlanarConvexHulls provides a `ConvexHull` type, which represents the convex hull of a set
of 2D points by its extreme points. Functionality includes:

* convexity test
* construction of a convex hull given a set of points
* area
* centroid
* point-in-convex-hull test
* closest point within convex hull
* equivalent halfspace representation of the convex hull

## Types

### The `ConvexHull` type

```@docs
ConvexHull
SConvexHull
DConvexHull
vertices
num_vertices
```

### `VertexOrder`s

```@docs
PlanarConvexHulls.VertexOrder
CCW
CW
```

## Algorithms

```@docs
is_ordered_and_strongly_convex
jarvis_march!
area
centroid
Base.in(point::PlanarConvexHulls.PointLike, hull::ConvexHull)
closest_point
hrep
hrep!
```
