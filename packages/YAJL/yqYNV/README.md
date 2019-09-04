# YAJL.jl [![Build Status](https://travis-ci.com/christopher-dG/YAJL.jl.svg?branch=master)](https://travis-ci.com/christopher-dG/YAJL.jl)

A Julia wrapper around the [YAJL JSON library](http://lloyd.github.io/yajl).

## Use Case

YAJL.jl is pretty niche since there are already very good JSON libraries in pure Julia [such](https://github.com/JuliaIO/JSON.jl) [as](https://github.com/samoconnor/LazyJSON.jl) [these](https://github.com/quinnj/JSON2.jl).
However, YAJL makes it possible to write highly custom JSON processors that never need to hold the entirety of the data in memory.

## Usage

It's quite easy to write your own custom JSON context.
You get to choose your data representation, and you only need to implement what you'll use.

Suppose that we had a massive list of numbers that we wanted to count.
Code for this task would look like this:

```julia
using YAJL

mutable struct Counter <: YAJL.Context
    n::BigInt
    Counter() = new(0)
end

YAJL.collect(ctx::Counter) = ctx.n
@yajl number(ctx::Counter, ::Ptr{UInt8}, ::Int) = ctx.n += 1

n = open(io -> YAJL.run(io, Counter()), "big_list.json")
```

Counting this list uses a constant amount of memory, regardless of the list length.

There are more basic examples in [`runtests.jl`](test/runtests.jl).
For a more complete example, see [`minifier.jl`](src/minifier.jl).
