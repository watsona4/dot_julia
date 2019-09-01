# EasyTranspose

Easily transpose arrays and vectors in Julia using `ᵀ`

```julia
using EasyTranspose
julia> [1, 2, 3]ᵀ == [1 2 3]
true


julia> A = randn(3,5);
julia> (A)ᵀ
5×3 Array{Float64,2}:
  1.05165    -1.56987   -0.227402
 -0.0827963  -0.314905  -0.126144
 -0.944382    0.245913   1.43961
 -0.799775    0.571537   0.199715
  0.369704   -0.323379  -0.49699
```




credits: Jeffrey Sarnoff, Michael K. Borregaard
