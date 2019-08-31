# ArrayAllez.jl

[![Build Status](https://travis-ci.org/mcabbott/ArrayAllez.jl.svg?branch=master)](https://travis-ci.org/mcabbott/ArrayAllez.jl)

```
] add ArrayAllez

add  Yeppp  Flux  AppleAccelerate
```

### `log! ∘ exp!`

This began as a way to more conveniently choose between [Yeppp!](https://github.com/JuliaMath/Yeppp.jl) 
and [AppleAccelerate](https://github.com/JuliaMath/AppleAccelerate.jl). Or neither... just loops with `@threads`?

```julia
x = rand(5);

y = exp.(x)  # = exp0(x) 

using Yeppp  # or using AppleAccelerate

y = exp!(x)  # with ! mutates
x = log_(y)  # with _ copies
```

Besides `log!` and `exp!`, there is also `scale!` which understands rows/columns. 
And `iscale!` which divides, and `inv!` which is an element-wise inverse.
All have non-mutating versions ending `_` instead of `!`, and simple broadcast-ed versions with `0`.

```julia
m = ones(3,7)
v = rand(3)
r = rand(7)'

scale0(m, 99)  # simply m .* 99
scale_(m, v)   # like m .* v but using rmul!
iscale!(m, r)  # like m ./ r but mutating.
m
```

### `∇`

These commands all make some attempt to define [Flux](https://github.com/FluxML/Flux.jl) gradients, 
but caveat emptor. There is also an `exp!!` which mutates both its forward input and its backward gradient, 
which may be a terrible idea.

```julia
using Flux
x = param(randn(5));
y = exp_(x)

Flux.back!(sum_(exp!(x)))
x.data == y # true
x.grad
```

This package also defines gradients for `prod` (overwriting an incorrect one) and `cumprod`, 
as in [this PR](https://github.com/FluxML/Flux.jl/pull/524). 

### `Array_`

An experiment with [LRUCache](https://github.com/JuliaCollections/LRUCache.jl) for working space:

```julia
x = rand(2000)' # turns off below this size

copy_(:copy, x)
similar_(:sim, x)
Array_{Float64}(:new, 5,1000) # @btime 200 ns, 32 bytes

inv_(:inv, x) # most of the _ functions can opt-in
```

### `broadsum`

This was an attempt to keep broadcasting un-`materialize`d, 
now done better by [LazyArrays.jl](https://github.com/JuliaArrays/LazyArrays.jl#broadcasting). 

### `⊙ = \odot`

Matrix multiplication, on the last index of one tensor & the first index of the next:

```julia
three = rand(2,2,5);
mat = rand(5,2);

p1 = three ⊙ mat

p2 = reshape(reshape(three,:,5) * mat ,2,2,2) # same

using Einsum
@einsum p3[i,j,k] := three[i,j,s] * mat[s,k]  # same
```

### `@dropdims`

This macro wraps reductions like `sum(A; dims=...)` in `dropdims()`.
It understands things like this:

```julia
@dropdims sum(10 .* randn(2,10); dims=2) do x
    trunc(Int, x)
end
```

### See Also

* [Vectorize.jl](https://github.com/rprechelt/Vectorize.jl) is a more comprehensive wrapper, including Intel MKL. 

* [Strided.jl](https://github.com/Jutho/Strided.jl) adds @threads to broadcasting. 

