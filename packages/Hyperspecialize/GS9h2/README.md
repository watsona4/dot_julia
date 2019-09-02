# Hyperspecialize

[![Travis](https://travis-ci.org/peterahrens/Hyperspecialize.jl.svg?branch=master)](https://travis-ci.org/peterahrens/Hyperspecialize.jl)
[![AppVeyor](https://ci.appveyor.com/api/projects/status/32r7s2skrgm9ubva/branch/master?svg=true)](https://ci.appveyor.com/project/peterahrens/hyperspecialize-jl/branch/master)
[![Coveralls](https://coveralls.io/repos/peterahrens/Hyperspecialize.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/peterahrens/Hyperspecialize.jl?branch=master)
[![Codecov](http://codecov.io/github/peterahrens/Hyperspecialize.jl/coverage.svg?branch=master)](http://codecov.io/github/peterahrens/Hyperspecialize.jl?branch=master)

Hyperspecialize is a proud hack of a Julia package designed to resolve method ambiguity errors by automating the task of redefining functions on more specific types!

## Problem

It is best to explain the problem (and solution) by example <sup>[1](#promote_type)</sup>. Suppose Peter and his friend Jarrett have both developed eponymous modules `Peter` and `Jarrett` as follows:

```julia
module Peter
  import Base.+

  struct PeterNumber <: Number
    x::Number
  end

  Base.:+(p::PeterNumber, y::Number) = PeterNumber(p.x + y)

  export PeterNumber
end

module Jarrett
  import Base.+

  struct JarrettNumber <: Number
    y::Number
  end

  Base.:+(x::Number, j::JarrettNumber) = JarrettNumber(x + j.y)

  export JarrettNumber
end
```

Peter and Jarrett have both defined fun numeric types! However, look what
happens when the user tries to use Peter's and Jarrett's numbers together...

```julia-repl
julia> using .Peter

julia> using .Jarrett

julia> p = PeterNumber(1.0) + 3
PeterNumber(4.0)

julia> j = 2.0 + JarrettNumber(2.0)
JarrettNumber(4.0)

julia> friends = p + j
ERROR: MethodError: +(::PeterNumber, ::JarrettNumber) is ambiguous. Candidates:
  +(x::Number, j::JarrettNumber) in Main.Jarrett at REPL[2]:8
  +(p::PeterNumber, y::Number) in Main.Peter at REPL[1]:8
Possible fix, define
  +(::PeterNumber, ::JarrettNumber)
```

Oh no! Since a `PeterNumber` is a `Number` and a `JarrettNumber` is a `Number`,
both `+` methods are applicable, and neither method is more specific. Julia has
no way to decide which method to use, and asks the user to decide by defining a
more specific method.

There is a question of what role developers should play in the resolution of
this ambiguity.

  * All developers can coordinate their efforts to agree on how their types
should interact, and then define methods for each interaction. This solution is
unrealistic since it poses an undue burden of communication on the developers
and since multiple behaviors may be desired for an interaction between types.
In the above example, the two definitions of `+` have different behavior and
either may be desired by the user.

  * The developer can write their library to run in a modifed execution
environment like [Cassette](https://github.com/jrevels/Cassette.jl). This
solution creates different contexts for multiple dispatch.

  * A single developer can define their ambiguous methods only on concrete
subtypes in `Base`, and provide utilities to extend these definitions. For
example, Peter could define `+` on all concrete subtypes of `Number` in Base.
In cases of ambiguity, `+` would then default to Jarrett's definition unless
the user asks for Peter's definition.

  Hyperspecialize is designed to standardize and provide utilities for the
latter approach.

## Load-Order Dependent Solution

  Peter decided to use Hyperspecialize, and now his definition looks like this:

```julia
  @replicable Base.:+(p::PeterNumber, y::@hyperspecialize(Number)) = PeterNumber(p.x + y)
```

  This solution will replicate this definition once for all concrete
subtypes of `Number`. This list of subtypes depends on the module load order.
If Peter's module is loaded first, we get the following behavior:

```julia-repl
julia> friends = p + j
JarrettNumber(PeterNumber(8.0))
```

If Jarrett's module is loaded first, we get the following behavior:

```julia-repl
julia> friends = p + j
PeterNumber(JarrettNumber(8.0))
```

## Explicit Solution

  Peter doesn't like this unpredictable behavior, so he decides to explicitly
define the load order for his types. He asks for his code to only be defined on
the concrete subtypes of `Number` in `Base`. He uses the `@concretize` macro to
define which subtypes of `Number` to use.  Now his definition looks like this:

```julia
  @concretize myNumber [BigFloat, Float16, Float32, Float64, Bool, BigInt, Int128, Int16, Int32, Int64, Int8, UInt128, UInt16, UInt32, UInt64, UInt8]

  @replicable Base.:+(p::PeterNumber, y::@hyperspecialize(myNumber)) = PeterNumber(p.x + y)
```

  Since Peter has only defined `+` for the concrete subtypes of Number, the user
will need to ask for a specific definition of `+` for a type they would like to
use. Consider what happens when Peter's package and Jarrett's package are
loaded together.

```julia-repl
julia> friends = p + j
JarrettNumber(PeterNumber(8.0))

julia> using Hyperspecialize

julia> @widen Peter.myNumber JarrettNumber
Set(Type[BigInt, Bool, UInt32, Float64, Float32, Int64, Int128, Float16, JarrettNumber, UInt128, UInt8, UInt16, BigFloat, Int8, UInt64, Int16, Int32])

julia> friends = p + j
PeterNumber(JarrettNumber(8.0))
```

Before the `myNumber` type tag in the `Peter` module is widened, there is no
definition of `+` for `PeterNumber` and `JarrettNumber` in the `Peter` package,
but since the `Jarrett` module defines a more generic method, that one is
chosen. After the user widens Peter's definition to include a JarrettNumber
(triggering a specific definition of `+` to be evaluated in Peter's module),
the more specific method in Peter's package is chosen.

## Opt-In, But Everyone Can Join

Suppose Jarrett has also been thinking about method ambiguities with Peter's
package and decides he will also use `Hyperspecialize`.

Now Jarret has added

```julia
  @concretize myNumber [BigFloat, Float16, Float32, Float64, Bool, BigInt, Int128, Int16, Int32, Int64, Int8, UInt128, UInt16, UInt32, UInt64, UInt8]

  @replicable Base.:+(x::@hyperspecialize(myNumber), j::JarrettNumber) = JarrettNumber(x + j.y)
```

to his module, and the behavior is as follows:

```julia-repl
julia> p + j
ERROR: no promotion exists for PeterNumber and JarrettNumber
Stacktrace:
 [1] error(::String, ::Type, ::String, ::Type) at ./error.jl:42
 [2] promote_to_supertype at ./promotion.jl:284 [inlined]
 [3] promote_result at ./promotion.jl:275 [inlined]
 [4] promote_type at ./promotion.jl:210 [inlined]
 [5] _promote at ./promotion.jl:249 [inlined]
 [6] promote at ./promotion.jl:292 [inlined]
 [7] +(::PeterNumber, ::JarrettNumber) at ./promotion.jl:321
 [8] top-level scope
```

There is now no method for adding a PeterNumber and a JarrettNumber! The user
must ask for one explicitly using `@widen` on either Peter or Jarrett's
`myNumber` type tag. If the user chooses to widen Jarrett's definitions, we get

```julia-repl
julia> @widen Jarrett.myNumber PeterNumber
Set(Type[BigInt, Bool, UInt32, Float64, Float32, Int64, Int128, Float16, PeterNumber, UInt128, UInt8, UInt16, BigFloat, Int8, UInt64, Int16, Int32])

julia> p + j
JarrettNumber(PeterNumber(8.0))
```

If the user instead chooses to widen Peter's definitions, we get

```julia-repl
julia> @widen Peter.myNumber JarrettNumber
Set(Type[BigInt, Bool, UInt32, Float64, Float32, Int64, Int128, Float16, UInt128, UInt8, UInt16, BigFloat, Int8, UInt64, JarrettNumber, Int16, Int32])

julia> p + j
PeterNumber(JarrettNumber(8.0))
```

# Getting Started

This library provides several functions for managing the defintions to
replicate and the types they are replicated over.

## Concretization

The user must enumerate the types that a definition is to replicated over. We
use *type tags* to describe a particular set of types. The type tag arguments
to macros are interpreted literally as symbols. The set of types is referred to
as the *concretization*.

  You may specify the concretization of a type tag using the `@concretize`
macro like this:
```julia
@concretize Key Int
```
You may specify more than one type:
```julia
@concretize Key (Int, Float64, Float32)
```
If you would like to expand the concretization of a type tag, use the
`@widen` macro.
```julia
@widen Key (BigFloat, Bool)
```
You may query the concretization of a type tag with the `@concretization`
macro.
```julia
@concretization Key
```
Type tags always have module-local scope and if no module is specified, they
are interpreted as belonging to the module in which they are expanded. You may
use the type tag form `mod.Key` to specify a module anywhere a type tag is
an argument to a macro.
```julia
@concretization(mod.Key)
```
If no concretization is given for a type tag `Key` in module `mod`, the tag
is given the default concretization corresponding to all the concrete subtypes
of whatever the symbol `Key` means when evaluated in `mod` (so if you are
making up a tag name, please define a concretization for it).

## Replicable

  The heart of the Hyperspecialize package is the `@replicable` macro, which
promises to replicate a definition for all combinations of types in the
concretization of type tags that appear in the definition. `@replicable` takes
only one argument, the code to be replicated at global scope in the current
module. To specify type tags, use the @hyperspecialize macro where the types in
the concretization of a tag should be substituted.

  Thus, the following example
```julia
module Foo
  @concretize MyKey (Int, Float32)
  @replicable bar(x::@hyperspecialize(MyKey), y::(@hyperspecialize MyKey)) = x + y
end
```
  will execute the following code at global scope in `Foo`.
```julia
bar(x::Int, y::Int) = x + y
bar(x::Float32, y::Int) = x + y
bar(x::Int, y::Float32) = x + y
bar(x::Float32, y::Float32) = x + y
```

  If someone has loaded the `Foo` module and calls
```julia
  @widen Foo.MyKey Float64
```
then the following code will execute at global scope in `Foo`.
```julia
bar(x::Float64, y::Float64) = x + y
bar(x::Int, y::Float64) = x + y
bar(x::Float32, y::Float64) = x + y
bar(x::Float64, y::Int) = x + y
bar(x::Float64, y::Float32) = x + y
```

Notice that the earlier definitions are not repeated.

# The Fine Print

This is an example of a module where the idea is simple and the details are not.

## Data And Precompilation

  Data is stored in `const global` dictionaries named `__hyperspecialize__` in
every module that calls `@concretize` (Note that this can happen implicitly if
other methods are called that expect a concretization to exist already).

For this reason (and to keep things simple), you cannot concretize a type tag
in a module that is not your own.

  Since this package works by calling "eval" on different modules to widen
types, if you want to call `@widen` on a type key in another module, you must
do so from the `__init__()` function in your module. See the documentation on
`__init__()`.

## When Is Hyperspecialize Right For Me?

There are three main drawbacks to the Hyperspecialize package.

  * These macros may generate a very large number of definitions if the
function definition includes many hyperspecialized type tags. For mathematical
operators this can be alleviated using Julia's promotion rules, but the problem
of how to define an unambiguous `promote_type` still stands. To further reduce
the number of methods that are defined, in some situations it may be sufficient
to only concretize the type tag to be a union of concrete types in Base. This
strategy works best if it is unlikely that the method will be redefined using
those types.

  * The second drawback is that the user must manually choose desired behavior,
so if the ambiguity is related to an internal type, the user may not know how
to resolve it.

  * The third drawback is that both methods that create an ambiguity may be
desired by a user, and they are forced to choose one global behavior. This can
be problematic if a different library has widened the same type tag and made
that choice for them already.

  In short, Hyperspecialize works best when the user knows which types are
being concretized, and when the resolution to method ambiguities is clear. A
major benefit to using Hyperspecialize is that you may keep your type-based
API, you are not forced to adopt a function-based API. If this is not something
that is important to you and you cannot work around difficulties involved in
using Hyperspecialize, you will likely be better off using a contextual
dispatch solution such as [Cassette](https://github.com/jrevels/Cassette.jl).

<a name="promote_type">1</a>: I have
chosen `+` as an example function, but it would be possible to define promotion
rules to avoid some ambiguities. However, it is possible that type ambiguities
may occur in the definition of the `promote_type` function.
