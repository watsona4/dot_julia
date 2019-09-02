# Linear Fractional Transformations

[![Build Status](https://travis-ci.org/scheinerman/LinearFractionalTransformations.jl.svg?branch=master)](https://travis-ci.org/scheinerman/LinearFractionalTransformations.jl)

[![Coverage Status](https://coveralls.io/repos/scheinerman/LinearFractionalTransformations.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/scheinerman/LinearFractionalTransformations.jl?branch=master)



This module defines a `LFT` data type to represent a complex *linear
fractional transformation*. This is a function on the extended
complex numbers (include complex infinity) defined by
```
f(z) = (a*z + b) / (c*z + d)
```
where `a,b,c,d` are (finite) complex numbers and `a*d-b*c != 0`.

These are also known as *Möbius transformations*.

## Constructors

The basic constructor takes four values:

```julia
julia> using LinearFractionalTransformations

julia> julia> f = LFT(1,2,3,4)
LFT( 1.0 + 0.0im , 2.0 + 0.0im , 3.0 + 0.0im , 4.0 + 0.0im )
```

Notice that the `LFT` is represented by a 2-by-2 complex matrix.
A `LFT` can also be defined by specifying a matrix.

```julia
julia> A = [1 2; 3 4];

julia> g = LFT(A)
LFT( 1.0 + 0.0im , 2.0 + 0.0im , 3.0 + 0.0im , 4.0 + 0.0im )
```

The identity `LFT` is constructed by `LFT()`:

```julia
julia> LFT()
LFT( 1.0 + 0.0im , 0.0 + 0.0im , 0.0 + 0.0im , 1.0 + 0.0im )
```

Given (complex) numbers `a,b,c` (including `Inf`) we can construct
a `LFT` that maps `a` to 0, `b` to 1, and `c` to infinity.

```julia
julia> f = LFT(2,5,-1)
LFT( 6.0 + 0.0im , -12.0 + 0.0im , 3.0 + 0.0im , 3.0 + 0.0im )

julia> f[2]
0.0 + 0.0im

julia> f[5]
1.0 + 0.0im

julia> f[-1]
Inf + Inf*im
```

Finally, we provide a constructor for mapping a given triple of values
`(a,b,c)` to another triple `(aa,bb,cc)`. The syntax is
`LFT(a,aa,b,bb,c,cc)`. Here's an example:

```julia
julia> f = LFT(1,2+im, 3,Inf, 4,1-im)
LFT( 5.0 + 1.0im , -17.0 - 7.0im , 3.0 + 0.0im , -9.0 + 0.0im )

julia> f[1]
2.0 + 1.0im

julia> f[3]
Inf + Inf*im

julia> f[4]
1.0 - 1.0im
```


#### Under the hood

The matrix representing a `LFT` object is held in a field named `:M`.

```julia
julia> f = LFT(1,2,3)
LFT( -1.0 + 0.0im , 1.0 + 0.0im , 1.0 + 0.0im , -3.0 + 0.0im )

julia> f.M
2x2 Array{Complex{Float64},2}:
 -1.0+0.0im   1.0+0.0im
  1.0+0.0im  -3.0+0.0im
```

## Operations

### Function application

Since a `LFT` is a function, the most basic operation we may wish to
perform is applying that function of a complex number. That's done
with `f[x]` notation (or with `f(x)`):

```julia
julia> f = LFT(3,2,1,1)
LFT( 3.0 + 0.0im , 2.0 + 0.0im , 1.0 + 0.0im , 1.0 + 0.0im )

julia> f[1]
2.5 + 0.0im

julia> f[0]
2.0 + 0.0im

julia> f[-1]
Inf + Inf*im

julia> f[Inf]
3.0 + 0.0im

julia> f[1+2im]
2.75 + 0.25im
```

**Note**: Staring in Julia 0.4, I plan to replace `f[x]` with `f(x)`
by defining `call`.

### Composition and inverse

The `*` operation is used for function composition.

```julia
julia> f = LFT(3,2,1,1);

julia> g = LFT(0,1,-1,2);

julia> f*g
LFT( -2.0 + 0.0im , 7.0 + 0.0im , -1.0 + 0.0im , 3.0 + 0.0im )

julia> g*f
LFT( 1.0 + 0.0im , 1.0 + 0.0im , -1.0 + 0.0im , 0.0 + 0.0im )
```


The inverse of a `LFT` is computed with `inv`:

```julia
julia> f = LFT(1,2,3,4);

julia> g = inv(f)
LFT( 4.0 + 0.0im , -2.0 - 0.0im , -3.0 - 0.0im , 1.0 + 0.0im )

julia> f*g
LFT( -2.0 + 0.0im , 0.0 + 0.0im , 0.0 + 0.0im , -2.0 + 0.0im )
```

Notice that the matrix representing `f*g` is a scaled version of the
identity matrix.

## Equality checking

We can use `==` or `isequal` to check if two `LFT` objects are
equal. Note that there is no unique matrix representation for a `LFT`
object and we might have that `f` and `g` are equal, but `f.M` and
`g.M` are different.

```julia
julia> f = LFT(1,2,3,4);

julia> g = LFT(-2,-4,-6,-8);

julia> f==g
true

julia> f.M == g.M
false
```
