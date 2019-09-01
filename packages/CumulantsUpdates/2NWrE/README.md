[![DOI](https://zenodo.org/badge/103524792.svg)](https://zenodo.org/badge/latestdoi/103524792)
[![Build Status](https://travis-ci.org/ZKSI/CumulantsUpdates.jl.svg?branch=master)](https://travis-ci.org/ZKSI/CumulantsUpdates.jl)
[![Coverage Status](https://coveralls.io/repos/github/ZKSI/CumulantsUpdates.jl/badge.svg?branch=master)](https://coveralls.io/github/ZKSI/CumulantsUpdates.jl?branch=master)

# CumulantsUpdates.jl

Updates following statistics of `n`-variate data
* `d`'th moment tensor,
* an array of moment tensors of order `1,2,...,d`.

Given `t` realisations of `n`-variate data: `X ∈ ℜᵗˣⁿ`, and the update `X + ∈ ℜᵘˣⁿ`
returns array of updated cumulant tensors of order `1,2,...,d`.

To store symmetric tensors uses a `SymmetricTensors` type, requires [SymmetricTensors.jl](https://github.com/ZKSI/SymmetricTensors.jl). To convert to array, run:

```julia
julia> Array(st::SymmetricTensors{T, d})
```
to convert back, run:

```julia
julia>  SymmetricTensor(a::Array{T,d})
```
Requires [Cumulants.jl](https://github.com/ZKSI/Cumulants.jl).

As of 01/01/2017 [kdomino](https://github.com/kdomino) is the lead maintainer of this package.

## Installation

Within Julia, run

```julia
pkg> add CumulantsUpdates
```

to install the files. Julia 0.7 or later is required.

## Parallel computation

For parallel computation just run
```julia
julia> addprocs(n)
julia> @everywhere using CumulantsUpdates
```

## Functions

### Data update

To update data `X ∈ ℜᵗˣⁿ` by the update `X+ ∈ ℜᵘˣⁿ` in the observation
window of size `t` and get `ℜᵗˣⁿ ∋ X' = vcat(X,X+)[1+u:end, :]` run:

```julia
julia> dataupdat(X::Matrix{T}, Xplus::Matrix{T}) where T<:AbstractFloat
```
the condition `u < t` must be fulfilled.

```julia
julia> a = ones(4,4)
4×4 Array{Float64,2}:
 1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0

julia> b = zeros(2,4)
2×4 Array{Float64,2}:
 0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0

julia> dataupdat(a,b)
4×4 Array{Float64,2}:
 1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0
 0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0
```

### Moment update

To update the moment tensor `M::SymmetricTensor{T, d}` for  data `X ∈ ℜᵗˣⁿ`, given the update `X+ ∈ ℜᵘˣⁿ` where `u < t` run

```julia
julia> momentupdat(M::SymmetricTensor{T, d}, X::Matrix{T}, Xplus::Matrix{T}) where {T<:AbstractFloat, d}
```

Returns a `SymmetricTensor{T, d}` of the moment tensor of updated multivariate data:
`ℜᵗˣⁿ ∈ X' = dataupdat(X,X+)`, i.e.: `M = moment(X, d)`, `momentupdat(M, X, X+) = moment(X', d)`. If `u ≪ t` `momentupdat()` is much faster than a recalculation.

```julia
julia> x = ones(6, 2);

julia> SymmetricTensor{Float64,3}(Union{Nothing, Array{Float64,3}}[[1.0 1.0; 1.0 1.0]

[1.0 1.0; 1.0 1.0]], 2, 1, 2, true)


julia> y = 2*ones(2,2);

julia> momentupdat(m, x, y)
SymmetricTensor{Float64,3}(Union{Nothing, Array{Float64,3}}[[3.33333 3.33333; 3.33333 3.33333]

[3.33333 3.33333; 3.33333 3.33333]], 2, 1, 2, true)

```

Function `momentarray(X, d)` can be used to compute an array of moments of order `1, ..., d`
of data `X ∈ ℜᵗˣⁿ`

```julia
julia> momentarray(X::Matrix{T}, d::Int, b::Int) where {T<:AbstractFloat, d}
```
`b` - is a `SymmetricTensor` parameter, a block size.

One can update an array of moments by calling:

```julia
julia> momentupdat(M::Array{SymmetricTensor{T, d}}, X::Matrix{T}, Xplus::Matrix{T}) where {T<:AbstractFloat, d}
```

Returns an `Array{SymmetricTensor{T, d}}` of moment tensors of order `1, ..., d` of updated multivariate data: `ℜᵗˣⁿ ∋ X' = dataupdat(X,X+)`, i.e. `Mₐᵣ = momentarray(X, d)`, `momentupdat(Mₐᵣ, X, X+) = momentarray(X', d)`. 

### Cumulants update

Presented functions are design for sequent update of multivariate cumulant tensors.
Hence it can be applied in a data streaming scheme. Suppose one has data `X ∈ ℜᵗˣⁿ`
and subsequent coming updates `X+ ∈ ℜᵘˣⁿ` such that `u ≪ t`. Suppose one want to compute cumulant tensors in an observation window of size `t` each time the update comes.
To store data amd moments we use the following structure `mutable struct DataMoments{T <: AbstractFloat}`
with following fields: `X` - data, `d` - maximal order of a moment series, `b` - a block size, `M` - moment series. To initialise, we can use the following constructor:

```julia
julia> DataMoments(X::Matrix{T}, d::Int, b::Int) where T <: AbstractFloat
```
here an array of moments will be computed. To update a DataMoments structure and compute updated cumulants run:

```julia

julia> cumulantsupdate!(dm::DataMoments{T}, Xplus::Matrix{T}) where T <: AbstractFloat

```
The function updates a DataMoment structure and returns a series of cumulants of order `1, ..., dm.d` for updated data. See:

```julia

julia> x = ones(10,2);

julia> s = DataMoments(x, 4, 2);

julia> y = zeros(4,2);

julia> cumulantsupdate!(s,y)[4]
SymmetricTensor{Float64,4}(Union{Nothing, Array{Float64,4}}[[-0.1056 -0.1056; -0.1056 -0.1056]

[-0.1056 -0.1056; -0.1056 -0.1056]

[-0.1056 -0.1056; -0.1056 -0.1056]

[-0.1056 -0.1056; -0.1056 -0.1056]], 2, 1, 2, true)
                 
```

To save the DataMoments structure use:

```julia

julia> savedm(dm::DataMoments, dir::String)
```

To load it use

```julia

julia> loaddm(dir::String)
```
returns a DataMoments structure stored in a given directory.


### The p-norm

```julia
julia> norm(st::SymmetricTensor{T, d}, p::Union{Float64, Int}) where {T<:AbstractFloat, d}
```

Returns a `p`-norm of the tensor stored as `SymmetricTensors`, supported for `k ≠ 0`. The output of `norm(st, p) = norn(convert(Array, st),p)`. However
`norm(st::SymmetricTensor, p)` uses the block structure implemented in `SymmetricTensors`, hence is faster and decreases the computer memory requirement.

```julia
julia> te = [-0.112639 0.124715 0.124715 0.268717 0.124715 0.268717 0.268717 0.046154];

julia> st = SymmetricTensor(reshape(te, (2,2,2)));

julia> norm(st)
0.5273572868359742

julia> norm(st, 2.5)
0.4468668679541424

julia> norm(st, 1)
1.339089
```
### Convert cumulants to moments and moments to cumulants

Given `M` a vector of moments of order `1, ..., d` to change it to a vector
of cumulants of order `1, ..., d` using

```julia
julia> function moms2cums!(M::Vector{SymmetricTensor{T}}) where T <: AbstractFloat
```
One can convert a vector of cumulants `c` to a vector of moments by running

```julia
julia> function cums2moms(c::Vector{SymmetricTensor{T}}) where T <: AbstractFloat
```

```julia

julia> m = momentarray(ones(20,3), 3, 2)
3-element Array{SymmetricTensor{Float64,N} where N,1}:
 SymmetricTensor{Float64,1}(Union{Nothing, Array{Float64,1}}[[1.0, 1.0], [1.0]], 2, 2, 3, false)                                                                                                                              
 SymmetricTensor{Float64,2}(Union{Nothing, Array{Float64,2}}[[1.0 1.0; 1.0 1.0] [1.0; 1.0]; nothing [1.0]], 2, 2, 3, false)                                                                                                   
 SymmetricTensor{Float64,3}(Union{Nothing, Array{Float64,3}}[[1.0 1.0; 1.0 1.0]
[1.0 1.0; 1.0 1.0] nothing; nothing nothing]
Union{Nothing, Array{Float64,3}}[[1.0 1.0; 1.0 1.0] [1.0; 1.0]; nothing [1.0]], 2, 2, 3, false)


julia> moms2cums!(m)

julia> m
3-element Array{SymmetricTensor{Float64,N} where N,1}:
 SymmetricTensor{Float64,1}(Union{Nothing, Array{Float64,1}}[[1.0, 1.0], [1.0]], 2, 2, 3, false)                                                                                                                          
 SymmetricTensor{Float64,2}(Union{Nothing, Array{Float64,2}}[[0.0 0.0; 0.0 0.0] [0.0; 0.0]; #undef [0.0]], 2, 2, 3, false)                                                                                                
 SymmetricTensor{Float64,3}(Union{Nothing, Array{Float64,3}}[[0.0 0.0; 0.0 0.0]
[0.0 0.0; 0.0 0.0] #undef; #undef #undef]
Union{Nothing, Array{Float64,3}}[[0.0 0.0; 0.0 0.0] [0.0; 0.0]; #undef [0.0]], 2, 2, 3, false)


julia> cums2moms(m)
3-element Array{SymmetricTensor{Float64,N} where N,1}:
 SymmetricTensor{Float64,1}(Union{Nothing, Array{Float64,1}}[[1.0, 1.0], [1.0]], 2, 2, 3, false)                                                                                                                          
 SymmetricTensor{Float64,2}(Union{Nothing, Array{Float64,2}}[[1.0 1.0; 1.0 1.0] [1.0; 1.0]; #undef [1.0]], 2, 2, 3, false)                                                                                                
 SymmetricTensor{Float64,3}(Union{Nothing, Array{Float64,3}}[[1.0 1.0; 1.0 1.0]
[1.0 1.0; 1.0 1.0] #undef; #undef #undef]
Union{Nothing, Array{Float64,3}}[[1.0 1.0; 1.0 1.0] [1.0; 1.0]; #undef [1.0]], 2, 2, 3, false)



```
# Performance tests

To analyse the computational time of cumulants updates vs `Cumulants.jl` recalculation, we supply the executable script `comptimes.jl`. The script saves computational times to the `res/*.jld` file. The scripts accept following parameters:
* `-d (Int)`: cumulant's maximum order, by default `d = 4`,
* `-n (vararg Int)`: numbers of marginal variables, by default `n = 40`,
* `-t (Int)`: number of realisations of random variable, by default `t = 500000`,
* `-u (vararg Int)`: number of realisations of update, by default `u = 10000, 15000, 20000`,
* `-b (Int)`: blocks size, by default `b = 4`,
* `-p (Int)`: numbers of processes, by default `p = 3`.

To analyse the computational time of cumulants updates for different block sizes `1 < b ≤ Int(√n)+2`, we supply the executable script `comptimesblocks.jl`.
The script saves computational times to the `res/*.jld` file. The scripts accept following parameters:
* `-d (Int)`: cumulant's order, by default `d = 4`,
* `-n (Int)`: numbers of marginal variables, by default `n = 48`,
* `-u (vararg Int)`: number of realisations of the update, by default `u = 10000, 20000`.
* `-p (Int)`: numbers of processes, by default `p = 3`.

To analyse the computational time of cumulants updates for different number of workers, we supply the executable script `comptimesprocs.jl`.
The script saves computational times to the `res/*.jld` file. The scripts accept following parameters:
* `-d (Int)`: cumulant's order, by default `d = 4`,
* `-n (Int)`: numbers of marginal variables, by default `n = 48`,
* `-u (vararg Int)`: number of realisations of the update, by default `u = 10000, 20000`,
* `-b (Int)`: blocks size, by default `b = 4`,
* `-p (Int)`: maximal numbers of processes, by default `p = 6`.

To plot computational times run executable `res/plotcomptimes.jl` on chosen `*.jld` file.


# Citing this work

Krzysztof Domino, Piotr Gawron, *Sliding window high order cumulant tensors calculation algorithm*, [arXiv:1701.06446](https://arxiv.org/abs/1701.06446)

This project was partially financed by the National Science Centre, Poland – project number 2014/15/B/ST6/05204.
