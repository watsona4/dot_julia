# PrePostCall

PrePostCall is a package which offers an intuitive syntax for making preceding and subsequent function calls to other functions using macros.

[![Build Status](https://travis-ci.org/sebastianpech/PrePostCall.jl.svg?branch=master)](https://travis-ci.org/sebastianpech/PrePostCall.jl)
[![codecov](https://codecov.io/gh/sebastianpech/PrePostCall.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/sebastianpech/PrePostCall.jl)
[![Coverage Status](https://coveralls.io/repos/github/sebastianpech/PrePostCall.jl/badge.svg?branch=master)](https://coveralls.io/github/sebastianpech/PrePostCall.jl?branch=master)

## Usage

### Simple Example

Here is a very simple example showing how to define a macro with PrePostCall which checks that 

- all passed arguments to a function are positive and
- the return value of a function is not `Inf`

Pre and post calls can be defined with `@pre` and `@post` respectively.
So first the new macros are defined:

``` julia
@pre positive(x::Number) = x<0 && error("Passed values must be positive!")
@post notInf(x::Number) = isinf(x) && error("The return value is Inf")
```

Now both macros `@positive` and `@notInf` can be applied to another function:

``` julia
@notInf @positive x y z function foo(x,y,z)
    (x+y)/z
end
```

Calls to `foo` with various arguments now result in the following:

``` julia
julia> foo(1,2,3)
1.0

julia> foo(1,-2,3)
ERROR: Passed values must be positive!

julia> foo(1,2,0)
ERROR: The return value is Inf
```

### Example with a mutable struct

In the following toy example you have a `mutable struct` where one field can either be an `Int` or `nothing`.
A function that is called with this `mutable struct` should only be usable if the field is **not** `nothing`.
Another function that is called with this `mutable struct` should only be usable if the field is **not** `nothing` and **at least** has a value of `3`.
(This example is minimized to illustrated the usage of PrePostCall.)

First define the struct:

``` julia
mutable struct Bar
    val::Union{Int,Nothing}
end
```

Then define the check functions:

``` julia
@pre alive(b::Bar) = b.val == nothing && error("Bar must not be nothing")
@pre large(b::Bar) = b.val < 3 && error("The value of bar must be >= 3")
```

The actual functions used on the `mutable type` can now be created with a clear, dense and easily readable definition:

``` julia
@alive addOne(b::Bar) = b.val += 1
@alive @large addTen(b::Bar) = b.val += 10
```

If no variable names are given for the newly created macros, the variables checked are assumed to have the same name as the ones used on the `@pre` (or `@post`) definitions.

Calls to the defined function with various `Bar`-types now result in the following:

``` julia
julia> a = Bar(1)
Bar(1)

julia> addOne(a)
2

julia> a.val = nothing

julia> addOne(a)
ERROR: Bar must not be nothing

julia> b = Bar(1)
Bar(1)

julia> addTen(b)
ERROR: The value of bar must be >= 3

julia> addOne(b)
2

julia> addOne(b)
3

julia> addTen(b)
13

julia> b.val = nothing

julia> addTen(b)
ERROR: Bar must not be nothing
```



