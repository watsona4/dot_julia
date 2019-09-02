# MemberFunctions.jl

`MemberFunctions.jl` helps writing member-like functions, reducing the amount of
code required to implement them. All functions prefixed by the `@member` macro
can access, i.e. read and write, fields of the first argument directly.

__Example__

```julia
mutable struct Foo
  value
end

@member get_value(foo::Foo) = value

@member function set_value!(foo::Foo, v)
  value = v
end

foo = Foo(1)
set_value!(foo, 2)

get_value(foo) == 1

set_value!(foo, 2)
get_value(foo) == 2
```
