# SimpleGF2


[![Build Status](https://travis-ci.org/scheinerman/SimpleGF2.jl.svg?branch=master)](https://travis-ci.org/scheinerman/SimpleGF2.jl)

[![Coverage Status](https://coveralls.io/repos/scheinerman/SimpleGF2.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/scheinerman/SimpleGF2.jl?branch=master)

[![codecov.io](http://codecov.io/github/scheinerman/SimpleGF2.jl/coverage.svg?branch=master)](http://codecov.io/github/scheinerman/SimpleGF2.jl?branch=master)


This a basic implementation of arithmetic in GF(2). Values in
GF(2) can be created like this:
```julia
julia> using SimpleGF2

julia> GF2(5)
GF2(1)

julia> GF2(4)
GF2(0)

julia> one(GF2)
GF2(1)

julia> zero(GF2)
GF2(0)
```
Matrices can be created with `ones`, `zeros`, and `eye`.
The `rand` function has been extended to return random
elements of GF(2). For example:
```julia
julia> A =rand(GF2,3,5)
3x5 Array{SimpleGF2.GF2,2}:
 GF2(0)  GF2(1)  GF2(1)  GF2(0)  GF2(0)
 GF2(1)  GF2(1)  GF2(1)  GF2(1)  GF2(1)
 GF2(0)  GF2(0)  GF2(0)  GF2(0)  GF2(1)
```
To see this clearly, you can map the values integers:
```julia
julia> map(Int,A)
3x5 Array{Int64,2}:
 0  1  1  0  0
 1  1  1  1  1
 0  0  0  0  1
```

Arithmetic with scalars and arrays of GF(2) elements
work as expected. For square matrices, `det` and `inv`
are available too:
```julia
julia> A = triu(ones(GF2,5,5))
5x5 Array{SimpleGF2.GF2,2}:
 GF2(1)  GF2(1)  GF2(1)  GF2(1)  GF2(1)
 GF2(0)  GF2(1)  GF2(1)  GF2(1)  GF2(1)
 GF2(0)  GF2(0)  GF2(1)  GF2(1)  GF2(1)
 GF2(0)  GF2(0)  GF2(0)  GF2(1)  GF2(1)
 GF2(0)  GF2(0)  GF2(0)  GF2(0)  GF2(1)

julia> inv(A)
5x5 Array{SimpleGF2.GF2,2}:
 GF2(1)  GF2(1)  GF2(0)  GF2(0)  GF2(0)
 GF2(0)  GF2(1)  GF2(1)  GF2(0)  GF2(0)
 GF2(0)  GF2(0)  GF2(1)  GF2(1)  GF2(0)
 GF2(0)  GF2(0)  GF2(0)  GF2(1)  GF2(1)
 GF2(0)  GF2(0)  GF2(0)  GF2(0)  GF2(1)

julia> A = triu(ones(GF2,4,4))
4x4 Array{SimpleGF2.GF2,2}:
 GF2(1)  GF2(1)  GF2(1)  GF2(1)
 GF2(0)  GF2(1)  GF2(1)  GF2(1)
 GF2(0)  GF2(0)  GF2(1)  GF2(1)
 GF2(0)  GF2(0)  GF2(0)  GF2(1)

julia> det(A)
GF2(1)

julia> B = inv(A)
4x4 Array{SimpleGF2.GF2,2}:
 GF2(1)  GF2(1)  GF2(0)  GF2(0)
 GF2(0)  GF2(1)  GF2(1)  GF2(0)
 GF2(0)  GF2(0)  GF2(1)  GF2(1)
 GF2(0)  GF2(0)  GF2(0)  GF2(1)

julia> A*B
4x4 Array{SimpleGF2.GF2,2}:
 GF2(1)  GF2(0)  GF2(0)  GF2(0)
 GF2(0)  GF2(1)  GF2(0)  GF2(0)
 GF2(0)  GF2(0)  GF2(1)  GF2(0)
 GF2(0)  GF2(0)  GF2(0)  GF2(1)
 ```


## Additional functionality

### Rank and nullity

Given a matrix `A` the dimension of its column space and its
null space can be computed using `rank(A)` and `nullity(A)`,
respectively. Further, the null space of `A` is returned by
`nullspace(A)` as a matrix whose columns are a basis for the
null space.
```julia
julia> A = rand(GF2,4,9)
4x9 Array{SimpleGF2.GF2,2}:
 GF2(1)  GF2(1)  GF2(0)  GF2(1)  GF2(0)  GF2(0)  GF2(1)  GF2(0)  GF2(0)
 GF2(1)  GF2(0)  GF2(1)  GF2(1)  GF2(0)  GF2(0)  GF2(1)  GF2(1)  GF2(0)
 GF2(1)  GF2(1)  GF2(0)  GF2(0)  GF2(1)  GF2(1)  GF2(1)  GF2(1)  GF2(0)
 GF2(0)  GF2(0)  GF2(0)  GF2(0)  GF2(1)  GF2(0)  GF2(0)  GF2(1)  GF2(1)

julia> rank(A)
4

julia> nullity(A)
5

julia> B = nullspace(A)
9x5 Array{SimpleGF2.GF2,2}:
 GF2(1)  GF2(1)  GF2(1)  GF2(1)  GF2(1)
 GF2(1)  GF2(0)  GF2(0)  GF2(1)  GF2(0)
 GF2(1)  GF2(0)  GF2(0)  GF2(0)  GF2(0)
 GF2(0)  GF2(1)  GF2(0)  GF2(0)  GF2(1)
 GF2(0)  GF2(0)  GF2(0)  GF2(1)  GF2(1)
 GF2(0)  GF2(1)  GF2(0)  GF2(0)  GF2(0)
 GF2(0)  GF2(0)  GF2(1)  GF2(0)  GF2(0)
 GF2(0)  GF2(0)  GF2(0)  GF2(1)  GF2(0)
 GF2(0)  GF2(0)  GF2(0)  GF2(0)  GF2(1)

julia> A*B
4x5 Array{SimpleGF2.GF2,2}:
 GF2(0)  GF2(0)  GF2(0)  GF2(0)  GF2(0)
 GF2(0)  GF2(0)  GF2(0)  GF2(0)  GF2(0)
 GF2(0)  GF2(0)  GF2(0)  GF2(0)  GF2(0)
 GF2(0)  GF2(0)  GF2(0)  GF2(0)  GF2(0)

julia> nullspace(A')
4x0 Array{SimpleGF2.GF2,2}
```

### Equation solving

Given a matrix `A` and a vector `b`, the function `solve(A,b)`
returns a vector `x` such that `A*x==b`. For example,
here we show how to solve the pair of equations `r+s==1, s+t==1`:
```julia
julia> A = map(GF2,[1 1 0; 0 1 1])
2x3 Array{SimpleGF2.GF2,2}:
 GF2(1)  GF2(1)  GF2(0)
 GF2(0)  GF2(1)  GF2(1)

julia> b = map(GF2,[1,1])
2-element Array{SimpleGF2.GF2,1}:
 GF2(1)
 GF2(1)

julia> x = solve(A,b)
3-element Array{SimpleGF2.GF2,1}:
 GF2(0)
 GF2(1)
 GF2(0)

julia> A*x==b
true
```
Of course, this is an underdetermined system. The function
`solve_all` returns a solution to the system `A*x==b` and
a basis for the null space of `A`:
```julia
julia> x,B = solve_all(A,b);

julia> x
3-element Array{SimpleGF2.GF2,1}:
 GF2(0)
 GF2(1)
 GF2(0)

julia> B
3x1 Array{SimpleGF2.GF2,2}:
 GF2(1)
 GF2(1)
 GF2(1)

julia> y = x + B[:,1]
3-element Array{SimpleGF2.GF2,1}:
 GF2(1)
 GF2(0)
 GF2(1)

julia> A*y==b
true
```

### Row reduced echelon form

The function `rref(A)` returns the row reduced echelon form
of the matrix `A`. Similarly, `rref!(A)` overwrites `A` with
its row reduced echelon form.



### Polynomials

The `SimpleGF2` module is compatible with the `Polynomials` package.

```julia
julia> using Polynomials

julia> x = Poly( [ GF2(0); GF2(1) ] )
Poly(x)

julia> (x+1)^4
Poly(GF2(1) + x^4)
```

## Installation

 Install with
 ```
 Pkg.clone("https://github.com/scheinerman/SimpleGF2.jl.git")
 ```

 And then specify `using SimpleGF2` to use the `GF2` numbers.



## Acknowledgement

Thanks to Tara Abrishami for her contributions to this module including
`rref`, `rref!`, `solve`, `solve_all`, and `nullspace`.
