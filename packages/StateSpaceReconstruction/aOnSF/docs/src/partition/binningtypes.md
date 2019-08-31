## Binning schemes

Currently, there are four types of rectangular partition schemes available, controlled by the parameter `ϵ`:

1. `ϵ::Int` divides each axis into `ϵ` intervals of the same size.
2. `ϵ::Float` divides each axis into intervals of size `ϵ`.
3. `ϵ::Vector{Int}` divides the i-th axis into `ϵᵢ` intervals of the same size.
4. `ϵ::Vector{Float64}` divides the i-th axis into intervals of size `ϵᵢ`.

There are two ways of representing a binning: either by encoding each bin by integers (see [Coordinate representation](@ref)), or by referencing them by the bin origin coordinates (see [Integer encoding representation](@ref)).

## Visualizing partitions

To visualize how the different partition schemes work, you can feed the `plot_partition`  a binning scheme `ϵ` along
with a three-dimensional set of points. *Of course, the partitions also work for data of any dimension.*

```@repl b1
using StateSpaceReconstruction, Plots
pgfplots()
```

```@repl b1
A = rand(3, 100)
```

Rectangular partition constructed by dividing the i-th axis interval into
an integer number, `ϵᵢ`, of equal-length intervals.

```@repl b1
ϵ = [1, 2, 3]
plot_partition(A, ϵ);
savefig("partition1.svg"); nothing # hide
```

![](partition1.svg)

Rectangular partition constructed by dividing the i-th axis into intervals of
length `ϵᵢ`.

```@repl b1
ϵ = [0.1, 0.3, 0.5]
plot_partition(A, ϵ);
savefig("partition2.svg"); nothing # hide
```

![](partition2.svg)


Rectangular partition constructed by dividing all axes into intervals of
length `ϵ`.

```@repl b1
ϵ = 0.3
plot_partition(A, ϵ);
savefig("partition3.svg"); nothing # hide
```

![](partition3.svg)


Rectangular bins, divide all axes into `ϵ` equal-length intervals.

```@repl b1
ϵ = 8
plot_partition(A, ϵ);
savefig("partition4.svg"); nothing # hide
```

![](partition4.svg)


## Visualizing partitions of embeddings
The same works with embeddings.


```@setup b1
using StateSpaceReconstruction, Plots
pgfplots()
```

```@repl b1
A = rand(3, 100)
E = embed(A, [1, 2, 3], [1, 0, -5])
```


Rectangular partition constructed by dividing the i-th axis of the embedding interval into an integer number, `ϵᵢ`, of equal-length intervals.

```@repl b1
ϵ = [1, 2, 3]
plot_partition(A, ϵ);
savefig("partition1b.svg"); nothing # hide
```

![](partition1b.svg)

Rectangular partition constructed by dividing the i-th axis of the embedding
into intervals of length `ϵᵢ`.

```@repl b1
ϵ = [0.1, 0.3, 0.5]
plot_partition(A, ϵ);
savefig("partition2b.svg"); nothing # hide
```

![](partition2b.svg)

Rectangular partition constructed by dividing all axes of the embedding into intervals of length `ϵ`.

```@repl b1
ϵ = 0.3
plot_partition(A, ϵ);
savefig("partition3b.svg"); nothing # hide
```

![](partition3b.svg)

Rectangular bins, divide all axes of the embedding into `ϵ` equal-length intervals.

```@repl b1
ϵ = 8
plot_partition(A, ϵ);
savefig("partition4b.svg"); nothing # hide
```

![](partition4b.svg)


## Customizing visualizations

```@docs
plot_partition
```
