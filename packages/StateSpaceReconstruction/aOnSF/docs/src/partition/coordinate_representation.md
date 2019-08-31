# Coordinate representation

Say we want to impose a rectangular binning on a set of points ``x_i`` using a
binning scheme specified by `ϵ`. One way of imposing a partition on
 ``x_i`` is to find the minima along each coordinate axis, then finding an N
such that ``N\epsilon\_i < x_i \leqq (N+1)\epsilon_i`` if starting from the
axis minimum. The marginal coordinate representing the point ``x_i`` is then the
lower boundary of the box, or ``N\epsilon\_i``. Together with the values of
`ϵ_i`, these coordinates completely specify each box.

An alternative representation of the box covering is the
[Integer encoding representation](@ref).

```@docs
assign_coordinate_labels(points, ϵ)
```

# Example
```@repl coordrep1
using StateSpaceReconstruction
using Plots; pgfplots() # hide
```

We'll create a set of random points and bin the space into rectangular boxes
with edge lengths ``\epsilon_1 = 0.19, \epsilon_2 = 0.15, \epsilon_3 = 0.12``.

```@repl coordrep1
pts = rand(3, 100)
ϵ = [0.19, 0.15, 0.12]
assign_coordinate_labels(pts, ϵ)
```

Each point is now assigned a bin. If a bin has multiple points visiting it,
there will be repeated columns.

Because this binning was in 3D, we can also visualize it:

```@repl coordrep1
plot_partition(pts, ϵ)
savefig("partcoord.svg"); nothing # hide
```

![](partcoord.svg)
