# Qutilities

Assorted utilities for quantum information.

Tested with Julia 1.0.


## Installation

```
pkg> add Qutilities
```


## Examples

```julia
julia> using Qutilities

julia> rho = [[1, 0, 0, 0] [0, 3, 3, 0] [0, 3, 3, 0] [0, 0, 0, 1]]/8.0
4×4 Array{Float64,2}:
 0.125  0.0    0.0    0.0
 0.0    0.375  0.375  0.0
 0.0    0.375  0.375  0.0
 0.0    0.0    0.0    0.125

julia> ptrace(rho)
2×2 Array{Float64,2}:
 0.5  0.0
 0.0  0.5
julia> ptranspose(rho)
4×4 Array{Float64,2}:
 0.125  0.0    0.0    0.375
 0.0    0.375  0.0    0.0
 0.0    0.0    0.375  0.0
 0.375  0.0    0.0    0.125

julia> purity(rho)
0.59375

julia> S_renyi(rho, 0)
2.0
julia> S_vn(rho)
1.061278124459133
julia> S_renyi(rho)
0.7520724865564145
julia> S_renyi(rho, Inf)
0.4150374992788438

julia> mutinf(rho)
0.9387218755408671
julia> concurrence(rho)
0.5
julia> formation(rho)
0.35457890266527003
julia> negativity(rho)
0.5849625007211562
```


## Testing

To run all the tests, activate the package before calling `test`:
```
pkg> activate .
(Qutilities) pkg> test
```


## License

Provided under the terms of the MIT license.
See `LICENSE` for more information.
