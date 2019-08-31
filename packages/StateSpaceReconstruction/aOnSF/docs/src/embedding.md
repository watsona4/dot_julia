# Reconstructions/embeddings

## What are embeddings?

If you haven't heard about state space reconstructions (SSR), or embeddings, visit the [Wikipedia page](https://en.wikipedia.org/wiki/Takens%27s_theorem) on Takens' theorem.


## Fully customizable embedding
Positive, zero and negative lags are possible. Negative lags are takes as
"past affects future", and positive lags  as "future affects past".

## Simple examples
For those familiar with SSR, performing reconstructions is easy as pie. The constructors accept arrays, vectors of vectors, vectors of `SVector`, `SArray`,
and `Dataset` instances from `DynamicalSystems.jl`.

The constructors accept both column-major arrays (points are column vectors) and row-major arrays (points are rows) arrays. Upon embedding, they are all converted
to column-major format.

First, some trivial examples.

```@repl e1
using StateSpaceReconstruction, StaticArrays, DynamicalSystems
using Plots; pgfplots() # hide
```

Simulate a three-dimensional orbit consisting of 100 points. We'll represent
the orbit as a regular array, as an `SMatrix` and as a `Dataset`.

```@repl e1
A = rand(3, 100)
S = SMatrix{3,100}(A)
D = Dataset(A)
```

Embed the raw orbits, performing no coordinate lagging.

```@repl e1
E_A = embed(A)
scatter3d(E_A, legend = false)# hide
savefig("embed1.svg"); nothing # hide
```

![](embed1.svg)

`Dataset` instances from `DynamicalSystems.jl` can also be embedded.

```@repl e1
E_D = embed(D)
scatter3d(E_D, legend = false) # hide
savefig("embed2.svg"); nothing # hide
```

![](embed2.svg)

Instances of `SMatrix` work just as well.

```@repl e1
E_S = embed(S)
scatter3d(E_S, legend = false) # hide
savefig("embed3.svg"); nothing # hide
```

![](embed3.svg)

Verify that all three embeddings are the same, regardless of which data type we're starting from.

```@repl e1
E_A == E_D == E_S
```


## Full control over the embedding
One can also specify exactly how the variables of the data should appear in the final embedding, and which embedding lag should be used for each variable.
Each variable of the data can appear multiple times in the final embedding with
different lags.

```@repl e2
using StateSpaceReconstruction, StaticArrays, DynamicalSystems
using Plots; pgfplots() # hide
```

```@repl e2
using StateSpaceReconstruction, StaticArrays, DynamicalSystems
A = rand(3, 100)
S = SMatrix{3,100}(A)
D = Dataset(A)
```

Embed the orbits, this time using coordinate lagging. Now, let ``x``, ``y``
and ``z`` be variables 1, 2 and 3 of the dataset `A`.  We'll create embeddings of the form ``E = \{(x(t+1), x(t), y(t), y(t-1), z(t))\}``. This means we will have to specify which variable will appear as which variables in the final embedding.

```@repl e2
which_pos = [1, 1, 2, 2, 3]
embed_lags = [1, 0, 0, -1, 1]
```

Using these positions and lags, we'll get 5-dimensional embeddings. In the plots below, the first three
coordinate axes are plotted.

```@repl e2
E_A = embed(A, which_pos, embed_lags)
scatter3d(E_A, legend = false) # hide
savefig("embed1b.svg"); nothing # hide
```

![](embed1b.svg)

```@repl e2
E_D = embed(D, which_pos, embed_lags)
scatter3d(E_D, legend = false) # hide
savefig("embed2b.svg"); nothing # hide
```

![](embed2b.svg)

```@repl e2
E_S = embed(S, which_pos, embed_lags)
scatter3d(E_S, legend = false) # hide
savefig("embed3b.svg"); nothing # hide
```

![](embed3b.svg)

Verify that all three embeddings are the same, regardless of which data type we're starting from.

```@repl e2
E_A == E_D == E_S
```
