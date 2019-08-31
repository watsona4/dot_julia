# Spec.jl

[![Build Status](https://travis-ci.org/zenna/Spec.jl.svg?branch=master)](https://travis-ci.org/zenna/Spec.jl)

[![codecov.io](http://codecov.io/github/zenna/Spec.jl/coverage.svg?branch=master)](http://codecov.io/github/zenna/Spec.jl?branch=master)

A package for expressing specifications.

# Usage

Spec.jl is (very small) library for specfiying correctness properties of programs.
Currently these serve both as functional tests (like asserts which can be disabled globally), or just a non-executable documentation.
The long term goal is to replicate much of the functionality of Spec in clojure, as well as formal verification methods.

```julia

function f()
  @pre x + y == 2
end
```

## Operations

Preconditions are defined using `@pre`

```julia
julia> f(x::Real) = (@pre x > 0; sqrt(x) + 5)
f (generic function with 1 method)

julia> f(-3)
ERROR: DomainError:
Stacktrace:
 [1] f(::Int64) at ./REPL[2]:1

julia> @with_pre begin
               f(-3)
             end
ERROR: ArgumentError: x > 0
Stacktrace:
```