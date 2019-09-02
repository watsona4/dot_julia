# [NonPromoting](https://github.com/eschnett/NonPromoting)

A Julia library for non-promoting type wrappers, i.e. for arithmetic
types that do not get automatically promoted to other types. This can
help prevent subtle type errors

[![Build Status (Travis)](https://travis-ci.org/eschnett/NonPromoting.jl.svg?branch=master)](https://travis-ci.org/eschnett/NonPromoting.jl)
[![Build status (Appveyor)](https://ci.appveyor.com/api/projects/status/m1rl6v9dgngsbeee?svg=true)](https://ci.appveyor.com/project/eschnett/nonpromoting-jl/branch/master)
[![Coverage Status (Coveralls)](https://coveralls.io/repos/github/eschnett/NonPromoting.jl/badge.svg?branch=master)](https://coveralls.io/github/eschnett/NonPromoting.jl?branch=master)

# Overview

Sometimes, Julia's automatic type promotion gets things subtly wrong.
This is especially a problem if you want a precision higher than
`Float64`, since `Float64` is often the default go-to type when a
floating point number is generated from non-floating-point numbers.

Here is an example. Of course, this code is so simple that one can
spot the problem right away. If multiple modules are involved, then
spotting this isn't that easy any more.

```Julia
function pi_plus_tenth_bad()
    x = big(pi)   # highly accurate
    y = 1/10      # unintentionally inaccurate
    x + y
end
```

The problem here is that the expression `1/10` has type `Float64`,
which is much less accurate than `BigFloat`. The error is difficult to
spot since the type `Float64` is not mentioned explicitly. `Float64`
just happens to be the default type that Julia chooses when dividing
two integers.

This version of the code does not have a problem:

```Julia
function pi_plus_tenth()
    x = big(pi)   # highly accurate
    y = 1//10     # infinitely accurate
    x + y
end
```

This uses a rational number to represent the fraction `1/10`, which is
arbitrarily accurate when converted to `BigFloat`.

One way to avoid such surprises is by avoiding automatic type
promotion. If the compiler refuses the expression `+(::BigFloat,
::Float64)`, then the error is quickly detected.

# Design

The module `NonPromoting` defines a wrapper type `NP{T}`. `T` is
expected to be a subtype of `AbstractFloat` such as `Float64`,
`BigFloat`, etc. This type supports all operations that `T` supports,
except that the automatic promotion rules to and from `T` are
disabled. Julia is very efficient for this kind of setup, and there is
zero run-time overhead.

To make a value non-promotable, call the constructor `NP{T}`. To
extract the value, convert it back to `T` with `convert(T, x)`. The
usual arithmetic operations (add, subtract, multiply, square root,
trigonometric functions, ...) are supported directly on the `NP{T}`
type.

The first (inaccurate) code looks like this:

```Julia
using NonPromoting
function pi_plus_tenth_bad()
    x = NP(big(pi))   # highly accurate
    y = NP(1/10)      # unintentionally inaccurate
    x + y             # ERROR REPORTED HERE
end
```

This code will now produce an error, because the addition
`+(::NP{BigFloat}, NP{Float64})` is not defined, and Julia will not
promote `NP{Float64}` to `NP{BigFloat}`.

This version is explicit about types and works correctly (i.e.
accurately):

```Julia
using NonPromoting
function pi_plus_tenth()
    x = NP{BigFloat}(pi)      # highly accurate
    y = NP{BigFloat}(1//10)   # also highly accurate
    x + y
end
```

The basic design idea is that one uses the type `NP{T}` instead of `T`
everywhere, except to interface with other modules who do not know
about `NonPromoting`.
