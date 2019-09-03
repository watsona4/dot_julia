[![Build Status](https://travis-ci.org/cometscome/RSCG.jl.svg?branch=master)](https://travis-ci.org/cometscome/RSCG.jl)

[![Coverage Status](https://coveralls.io/repos/github/cometscome/RSCG.jl/badge.svg?branch=master)](https://coveralls.io/github/cometscome/RSCG.jl?branch=master)

# RSCG.jl

This package can calculate the elements of the Green's function:

```math
G_ij(σk) = ([σj I - A]^-1)_{ij},
```

with the use of the reduced-shifted conjugate gradient method
(See, Y. Nagai, Y. Shinohara, Y. Futamura, and T. Sakurai,[arXiv:1607.03992v2 or DOI:10.7566/JPSJ.86.014708]).
One can obtain ``G_{ij}(\sigma_k)`` with different frequencies ``\sigma_k``, simultaneously.

The matrix should be symmetric or hermitian.

We can use Arrays, LinearMaps, and SparseArrays.

This software is written in Julia 1.0.

This software is released under the MIT License, see LICENSE.

## Install

```
add https://github.com/cometscome/RSCG.jl
```

## Example
Let us obtain the Green' functions ``G(z)`` on the complex plane.

```julia
M = 100
σ = zeros(ComplexF64,M)
σmin = -4.0*im-1.2
σmax = 4.0*im +4.3
for i=1:M
    σ[i] = (i-1)*(σmax-σmin)/(M-1) + σmin
end
```

We define the matrix:

```julia
using SparseArrays


function make_mat(n)
    A = spzeros(Float64,n,n)
    t = -1.0
    μ = -1.5
    for i=1:n
        dx = 1
        jp = i+dx
        jp += ifelse(jp > n,-n,0) #+1
        dx = -1
        jm = i+dx
        jm += ifelse(jm < 1,n,0) #-1
        A[i,jp] = t
        A[i,i] = -μ
        A[i,jm] = t
    end
    return A
end

n=1000
A1 = make_mat(n)
```

Or, we can also use LinearMaps.jl to define the matrix:

```julia
using LinearMaps

function set_diff(v)
    function calc_diff!(y::AbstractVector, x::AbstractVector)
        n = length(x)
        length(y) == n || throw(DimensionMismatch())
        μ = -1.5
        for i=1:n
            dx = 1
            jp = i+dx
            jp += ifelse(jp > n,-n,0) #+1
            dx = -1
            jm = i+dx
            jm += ifelse(jm < 1,n,0) #-1
            y[i] = v*(x[jp]+x[jm])-μ*x[i]
        end

        return y
    end
    (y,x) -> calc_diff!(y,x)
end

n=1000
Al = set_diff(-1.0)
A2 = LinearMap(Al, n; ismutating=true,issymmetric=true)
```

### an element
If we want to obtain the element ``G_{ij}(σ_k)``,

```julia
i = 1
j = 1
Gij1 = greensfunctions(i,j,σ,A1) #SparseArrays
Gij2 = greensfunctions(i,j,σ,A2) #LinearMaps
```

### elements

If we want to obtain the elements ``G_{ij}(σ_k)`` with different i,

```julia
vec_i = [1,4,8,43,98]
j = 1
vec_Gij1 = greensfunctions(vec_i,j,σ,A1) #SparseArrays
vec_Gij2 = greensfunctions(vec_i,j,σ,A2) #LinearMaps
```



## Functions

greensfunctions(i::Integer,j::Integer,σ::Array{ComplexF64,1},A)

Inputs:

* `i` :index of the Green's function

* `j` :index of the Green's function

* `σ` :frequencies

* `A` :hermitian matrix. We can use Arrays,LinearMaps, SparseArrays

* `eps` :residual (optional) Default:`1e-12`

* `maximumsteps` : maximum number of steps (optional) Default:`20000`

Output:
* `Gij[1:M]`: the matrix element Green's functions at M frequencies defined by ``\sigma_k``.

greensfunctions(vec_left::Array{<:Integer,1},j::Integer,σ::Array{ComplexF64,1},A)

Inputs:

* `vec_left` :i indices of the Green's function

* `j` :index of the Green's function

* `σ` :frequencies

* `A` :hermitian matrix. We can use Arrays,LinearMaps, SparseArrays

* `eps` :residual (optional) Default:`1e-12`

* `maximumsteps` : maximum number of steps (optional) Default:`20000`

Output:
* `Gij[1:M,1:length(vec_left)]`: the matrix element Green's functions at M frequencies defined by ``\sigma_k``.
