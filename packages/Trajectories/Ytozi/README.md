# Trajectories

A trajectory in the sense of this package is a vector of time points `t` and a corresponding
vector of spatial points `x`, which are though as locations `x[i]` of an object at times
`t[i]`.

A key decision which has to be made for a time series object,
is whether iteration is used to iterate values, pairs or is leveraged for destruction. See issue #1. At the moment, 
all iteration and destructuring is explicit.

To iterate values `xᵢ`, pairs `(tᵢ, xᵢ)` or components `(t, x)`, use `values`, `pairs` or `Pair`
```julia
tᵢ in keys(X)
xᵢ in values(X)
(tᵢ, xᵢ) in pairs(X)

t, x = Pair(X)
```

A second key decision is what constitutes indexing. Also here this package is *agnostic*: Only key look-up
with `get` is implemented so far.

Trajectories support `Tables.jl` with `columns` being a named tuple `(t = X.t, x = X.x)`.
