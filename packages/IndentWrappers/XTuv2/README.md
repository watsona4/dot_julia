# IndentWrappers

![Lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)<!--
![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![Lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) -->
[![Build Status](https://travis-ci.com/tpapp/IndentWrappers.jl.svg?branch=master)](https://travis-ci.com/tpapp/IndentWrappers.jl)
[![codecov.io](http://codecov.io/github/tpapp/IndentWrappers.jl/coverage.svg?branch=master)](http://codecov.io/github/tpapp/IndentWrappers.jl?branch=master)

## Usage

`indent(io, n)` returns an `::IO` object that writes `n` spaces after each `\n`.

`indent`s can be chained, use in a functional way. It is recommended that implementations of `Base.show` using this package never close with a newline.

Example:

```julia
struct Foo
    contents
end

function Base.show(io::IO, foo::Foo)
    print(io, "This is a Foo with the following contents:")
    let inner_io = indent(io, 4)
        for elt in foo.contents
            print(inner_io, '\n', elt)
        end
    end
end
```

then

```julia
julia> Foo(['a', 42, "string"])
This is a Foo with the following contents:
    a
    42
    string
```

## Similar packages

- [IOIndents.jl](https://github.com/KristofferC/IOIndents.jl), which inspired part of the implementation
