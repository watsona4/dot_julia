# RequiredKeywords

[![Build Status](https://travis-ci.org/adamslc/RequiredKeywords.jl.svg?branch=master)](https://travis-ci.org/adamslc/RequiredKeywords.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/b8qbm03hh9knhvxb?svg=true)](https://ci.appveyor.com/project/adamslc/requiredkeywords-jl)
[![codecov.io](http://codecov.io/github/adamslc/RequiredKeywords.jl/coverage.svg?branch=master)](http://codecov.io/github/adamslc/RequiredKeywords.jl?branch=master)

This package allows you to specify required keyword arguments, as suggusted in https://github.com/JuliaLang/julia/issues/5111.

As of Julia version 0.7.0, this functionality is built in. From this version forward, the `@required_keywords` macro won't do anything.

# Usage
```julia
julia> using RequiredKeywords

julia> @required_keywords f(x; y::Int64) = x*y
f (generic function with 1 method)

julia> f(2,y=2)
4

julia> f(2)
ERROR: Unassigned Keyword:  Required keyword y::Int64 not included.
Stacktrace:
 [1] f(::Int64) at ./REPL[5]:1
```
