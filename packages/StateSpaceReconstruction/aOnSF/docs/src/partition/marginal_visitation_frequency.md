# Marginal visitation frequencies

In a system of many variables, it can be useful to find the marginal visitation frequencies after assigning a partition
to the set of points. The following function computes marginal visitation frequencies along the coordinate axes
specified by `along_which_axes` for a set of `points` partitioned into boxes in the manner specified by `ϵ`.

Marginal visitation frequencies may also be computed directly from the partition representation of the points
in question. Here, `visited_bins` is the output of either [`assign_bin_labels`](@ref) or
[`assign_coordinate_labels`](@ref).

In both cases, visitation frequencies are calculated by counting the number
of points falling in each bin (i.e. the multiplicity of the bin),
then normalizing by the total number of points.

```@docs
marginal_visitation_freq
```

```@setup marginal
using StateSpaceReconstruction
using Plots; pyplot()
pts = rand(5, 60)
ϵ = 6
jointvisitfreq = marginal_visitation_freq(1:5, pts, ϵ)

bar(jointvisitfreq, size = (400, 500)); # hide
```

# Examples

```@repl marginal
using StateSpaceReconstruction
using Plots; pyplot()
pts = rand(5, 300) # hide
ϵ = 7 # hide
marginal_visitation_freq(1, pts, ϵ); # hide
```

## Marginals for one variable at a time
Let's create a 5D dataset of 600 points and compute the marginals for each individual coordinate axis,
given a partition where each axis is divided into 7 equal-length intervals.

```@repl marginal
pts = rand(5, 600)
ϵ = 7
Ms = [marginal_visitation_freq(i, pts, ϵ) for i = 1:5]
Ms = hcat(Ms...) # convert to array

heatmap(Ms, xlabel = "Coordinate axis #", ylabel = "Bin #", size = (300, 500));
savefig("marginalindividual.svg"); nothing # hide
```

![](marginalindividual.svg)

## Marginals for multiple variables
We can also compute the marginals of multiple variables. For this example,
choose variables `1:2`, `2:3` and `[3, 5]`.

```@repl marginal
pts = rand(5, 600)
ϵ = 7
Ms = [marginal_visitation_freq(i, pts, ϵ) for i = [1:2, 2:3, [3, 5]]]
Ms = hcat(Ms...) # convert to array

heatmap(Ms, xlabel = "Coordinate axis #", ylabel = "Bin #", size = (300, 500));
savefig("marginalmultiple.svg"); nothing # hide
```

![](marginalmultiple.svg)

## Joint visitation frequency
Computing the marginals for all available variables corresponds to computing the joint visitation frequency.

```@repl marginal
pts = rand(5, 1000)
ϵ = 2
jointvisitfreq = marginal_visitation_freq(1:5, pts, ϵ)

bar(jointvisitfreq, size = (400, 500), legend = false)
xlabel!("State #"); ylabel!("Visitation frequency");
savefig("jointvisit.svg"); nothing # hide
```

![](jointvisit.svg)


The plot above shows the visitation frequency over the visited bins.
