# Simplex partitions
Simplex partitions are formed by performing a Delaunay triangulation
of the points, forming a set of disjoint simplices entirely covering
the point cloud.


## Example

```@repl simplex1
using StateSpaceReconstruction
using Plots
```

Create a set of random points (just a few, so it doesn't take forever to plot
the triangulation), and triangulate them.

```@repl simplex1
E = embed(rand(3, 20))
tri = delaunaytriang(E)
```

```@repl simplex1
plot_triang(E, tri, vertices = true);
savefig("triang.svg"); nothing # hide
```

![](triang.svg)
