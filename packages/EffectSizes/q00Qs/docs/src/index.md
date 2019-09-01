# EffectSizes.jl

EffectSizes.jl is a Julia package for effect size measures. Confidence intervals are
assigned to effect sizes using either the normal distribution or by bootstrap resampling.
The package implements types for the following measures:

**Measure** | **Type**
---|---
Cohen's *d* | `CohenD`
Hedge's *g* | `HedgeG`
Glass's *Δ* | `GlassΔ`

## Installation

```julia
] add https://github.com/harryscholes/EffectSizes.jl
```

## Examples

```julia
julia> using Random, EffectSizes; Random.seed!(1);

julia> xs = randn(10^3);

julia> ys = randn(10^3) .+ 0.5;

julia> es = CohenD(xs, ys) # normal CI
-0.507, 0.95CI (-0.924, -0.089)

julia> effectsize(es)
-0.506674937960848

julia> quantile(es)
0.95

julia> CohenD(xs, ys, quantile=0.99)
-0.507, 0.99CI (-1.056, 0.042)

julia> CohenD(xs, ys, 10^4) # bootstrap CI
-0.507, 0.95CI (-0.594, -0.417)

julia> ci = confint(es)
0.95CI (-0.924, -0.089)

julia> confint(ci)
(-0.9244427501651218, -0.08890712575657417)

julia> lower(ci)
-0.9244427501651218

julia> upper(ci)
-0.08890712575657417

julia> quantile(ci)
0.95
```

## Index

```@index
```

## API

```@docs
EffectSizes.AbstractEffectSize
CohenD
EffectSize
HedgeG
GlassΔ
EffectSizes.ConfidenceInterval
EffectSizes.BootstrapConfidenceInterval
effectsize
confint
lower
upper
quantile
```
