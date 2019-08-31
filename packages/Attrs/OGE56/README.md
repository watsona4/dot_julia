
# Attrs

[![Build Status](https://travis-ci.org/simonfxr/Attrs.jl.svg?branch=master)](https://travis-ci.org/simonfxr/Attrs.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/02eg0ctefyvpufe9?svg=true)](https://ci.appveyor.com/project/simonfxr/attrs-jl)
[![codecov.io](http://codecov.io/github/simonfxr/Attrs.jl/coverage.svg?branch=master)](http://codecov.io/github/simonfxr/Attrs.jl?branch=master)

Give Attribtures the treatment they deserve: use dynamic dispatch to implement
an extensible mechanism for user provided attributes.

## Background

Julia 0.7+ makes it possible to overload property access via `Base.getproperty`
and `Base.setproperty!`, and uses `Symbols` to name a property. This makes it
easier to use in dynamic scenarios (e.g. Python interoperability), but has one
huge drawback: all the coded related to properties for a single type has to be
in one single place and can thus not be extended. This is not the Julian way of
using dynamic dispatch to get the usual extensibility along multiple dimensions
we know and love!

## Performance: `Base.getproperty` and Inlining

There is another problem with getproperty/setproperty this package tries to adress: performance. Consider this code:

```julia
struct Foo
    x::Int
end

function compute_y(a::Foo)
    return a.x * 2 + 1
end

@inline function Base.getproperty(a::Foo, f::Symbol)
    (f === :x) && return getfield(a, :x)
    (f === :y) && return compute_y(a)
    error("type $(typeof(a)) has no field $f")
end

f(a::Foo) = a.y

code_native(f, (Foo,))
# Output:
#  .text
#  [...]
#  pushq    %rax
#  movabsq  $julia_getproperty_36741, %rax
#  movabsq  $116219542556536, %rsi  # imm = 0x69B3788CCF78
#  callq    *%rax
#  [...]
#  leaq     1(%rax,%rax), %rax
#  popq     %rcx
#  retq
#  nop 
```

Why is `getproperty` not inlined? The problem is getproperty calling `compute_y`
which itself calls `getproperty` (after lowering `a.x`). So the compiler
rightfully refuses to do recursive inlining (there are ways around it, e.g.
partial inlining, but lets appreciate what we have!). One fix is to replace
`a.x` with `getfield(a, :x)` to break the cycle in the call graph. 

This package provides a similar solution via the `@literalattrs` macro. This
macro replaces the property access with `literal_getattr` and
`literal_setattr!`, to avoid the cyclic call graph.

```julia
using Attrs

@defattrs Foo

@literalattrs function compute_y(a::Foo)
    return a.x * 2 + 1
end

@inline Attrs.getattr(a::Foo, ::Attr{:y}) = compute_y(a)

code_native(f, (Foo, ))
# Output:
#    .text
#    movq    (%rdi), %rax
#    leaq    1(%rax,%rax), %rax
#    retq
#    nopl    (%rax)
```

Now `compute_y(a)` has been inlined!

## How to use

First define your type as usual:
```julia
struct MyType
   [...]
end
```

Make your type opt in to the `Attrs` package (after `using Attrs`):
```julia
@defattrs MyType
@defattrs MyOtherType{X, Y} where {X<:AbstractFloat, Y<:Integer}
```

Define your attributes, make sure all `gettatr`/`settattr!` methods of your type
use the `@literalattrs` macro to make inlining possible.
```julia
@inline @literalattrs Attrs.getattr(x::MyType, ::Attr{:foo}) = [...]

@inline @literalattrs Attrs.setattr!(x::MyType, ::Attr{:foo}, y) = [...]
```

Now just use your type as usual: `f(x::MyType) = x.y` no `@literalattrs` is
necessary at this point!
