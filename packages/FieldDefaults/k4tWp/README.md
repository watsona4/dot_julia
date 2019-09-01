# FieldDefaults

[![Build Status](https://travis-ci.org/rafaqz/FieldDefaults.jl.svg?branch=master)](https://travis-ci.org/rafaqz/FieldDefaults.jl)
[![Coverage Status](https://coveralls.io/repos/rafaqz/FieldDefaults.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/rafaqz/FieldDefaults.jl?branch=master)
[![codecov.io](http://codecov.io/github/rafaqz/FieldDefaults.jl/coverage.svg?branch=master)](http://codecov.io/github/rafaqz/FieldDefaults.jl?branch=master)

A lightweight package that adds keyword defaults to (the also lightweight!)
[FieldMetadata.jl](https://github.com/rafaqz/FieldMetadata.jl).

The `@default_kw` macro adds a keyword arg constructor to a type:

```julia
@default_kw struct MyStruct
    foo::Int | 1
    bar::Int | 2
end

julia> m = MyStruct()
julia> m.foo
1

julia> m.bar
2
```

It has a similar outcome (though entirely difference mechanism) to
Parameters.jl. It has some limitations: presently it only adds an outside
constructor, and defaults can't use the other default values.

But it has some other nice features. Defaults can be added to a struct that has
already been defined by prefixing `re` to the macro name, as in
FieldMetadata.jl:

```julia
struct SomeoneElseDefined
    foo::Int
    bar::Int
end

@redefault struct SomeoneElseDefined
    foo | 7
    bar | 19
end
```

Each default value can also be overridden by declaring a new function:

```
default(::YourType, ::Type{Val{:fieldname}}) = 99
```

The `u@default_kw` behaves as `@default_kw` but combines defaults
with the units metadata field in the constructor.


## Additional info

Extra metadata fields are easy to add to a struct at definition time or
afterwards, using a [@metadata](https://github.com/rafaqz/FieldMetadata.jl) macro.

Default values of single structs or more complex composite types can be
flattened to tuples or vectors using
[Flatten.jl](https://github.com/rafaqz/Flatten.jl). This can be combined with
fieldnames, other metadata and current field values for generating tabular
displays, or other uses.
