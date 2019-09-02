The recommended way to get data is through `Mangal.jl` integration with the
`EcologicalNetworks.jl` package for networks analysis.

There is no obvious way to know in advance if a network is bipartite or not. For
this reason, this wrapper *only* returns unipartite objects. They can be
converted into bipartite networks using the `convert` methods in
`EcologicalNetworks.jl`.

## Generate network objects

```@docs
convert
```

## Increase taxonomic resolution

```@docs
taxonize
```
