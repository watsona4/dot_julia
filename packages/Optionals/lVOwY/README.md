# Optionals

[![Build Status](https://travis-ci.org/simonfxr/Optionals.jl.svg?branch=master)](https://travis-ci.org/simonfxr/Optionals.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/ggcdgreed39my8ca?svg=true)](https://ci.appveyor.com/project/simonfxr/optionals-jl)
[![Coverage Status](https://coveralls.io/repos/simonfxr/Optionals.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/simonfxr/Optionals.jl?branch=master)
[![codecov](https://codecov.io/gh/simonfxr/Optionals.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/simonfxr/Optionals.jl)

This Package provides the `Optional{T}` type, this type is a simple wrapper
around `Union{T, Missing}` at least semantically.

## Why should I use this package?
In Julia 0.7 and above the `Union{T, Missing}` type makes it quite convenient to
use fields with optional values. The Missings package tries to backport this
feature to 0.6, unfortunately v0.6 is not very efficient in using Union fields.
In the interim `Optional` provides a somewhat more efficient way for packages
which need to support both v0.6 and newer. After dropping support for v0.6 and
older, `Optional{T}` can simply be replaced with `Union{T, Missing}` (hopefully)
without further changes.

## How to use

    using Optionals
    
    struct Foo
       x::Optional{Int}
    end
    
Construction without a value: `Foo(missing)`

Construction with a value: `Foo(42)`
    
Test if field `x` has a value: `ismissing(foo.x)`

Get value or replace missing with default: `coalesce(foo.x, 42)`

Convert an `Optional{T}` to a `Union{T, Missing}`: `coalesce(foo.x)`
