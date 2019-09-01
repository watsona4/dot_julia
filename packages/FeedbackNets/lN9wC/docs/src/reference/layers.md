# Layer Types

Currently, a basic `Merger` layer and a `Splitter` layer are implemented. In
addition, there are several convenience layers for the preimplemented models.

## Mergers

```@autodocs
Modules = [Mergers]
```

## Splitters

```@autodocs
Modules = [Splitters]
```

## Other layers

The preimplemented models use a flattening layer and local response normalization.

```@docs
flatten(x)
```

```@autodocs
Modules = [LRNs]
```
