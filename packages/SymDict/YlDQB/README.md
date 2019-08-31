# SymDict

Convenience functions for dictionaries with `Symbol` keys.

[![Build Status](https://travis-ci.org/samoconnor/SymDict.jl.svg)](https://travis-ci.org/samoconnor/SymDict.jl)

Create a `Dict{Symbol,}`:

```julia
@SymDict(a=1, b=2)

Dict{Symbol,Any}(:a=>1,:b=>2)
```


Capture local variables in a dictionary:

```julia
a = 1
b = 2
@SymDict(a,b)

Dict{Symbol,Any}(:a=>1,:b=>2)
```

```julia
a = 1
b = 2
@SymDict(a,b,c=3)

Dict{Symbol,Any}(:a=>1,:b=>2,:c=3)
```


Capture varags key,value arguments in a dictionary:

```julia

function f(x; option="Option", args...)
    @SymDict(x, option, args...)
end

f("X", foo="Foo", bar="Bar")

Dict{Symbol,Any}(:x=>"X",:option=>"Option",:foo=>"Foo",:bar=>"Bar")
```


Merge new entries into a dictionary:

```julia
d = @SymDict(a=1, b=2)
merge!(d, c=3, d=4)

Dict{Symbol,Any}(:a=>1,:b=>2,:c=3,:d=>4)
```


Convert to/from `Dict{AbstractString,}:

```julia
d = @SymDict(a=1, b=2)
d = stringdict(d)

Dict{String,Any}("a"=>1,"b"=>2)

d = symboldict(d)

Dict{Symbol,Any}(:a=>1,:b=>2)
```
