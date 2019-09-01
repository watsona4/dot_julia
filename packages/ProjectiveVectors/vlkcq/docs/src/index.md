Data structure for elements projective space as well as in in products of projective spaces.

## Type
```@docs
PVector
```
## Informations

```@docs
dims
homvars
dimension_indices
dimension_indices_homvars

```
## Conversion between affine and projective space
```@docs
affine_chart
affine_chart!
embed
```

## Other methods
```@docs
data
norm_affine_chart
norm(z::PVector)
normalize!(::PVector)
normalize(::PVector)
dot(v::PVector{T, N}, w::PVector{T2, N}) where {T, T2, N}
rmul!(z::PVector{T, 1}, λ::Number) where {T}
fubini_study
```
