# Manual

## Issue

Let's assume you have an observable of type `Int`. You want to add the following measurements to your observable:
```julia
x = Int[44, -70, 14, -32, 18]
```

The mean of the observable should afterwards be `mean(x) == -5.2`. Note that this value, `-5.2`, exceeds the type `Int`. Explicitly we can see this if we try to convert it to `Int`:
```julia
julia> convert(Int, mean(x))
ERROR: InexactError()
Stacktrace:
 [1] convert(::Type{Int}, ::Float64) at .\float.jl:679
```

This is, of course, not a particularity of the type `Int` but happens for many (discrete) data types.


## Default

Let us try the above example explicitly. We create an integer observable,
```julia
julia> myobs = Observable(Int, "My Observable");
```
and add the measurements,
```julia
julia> add!(myobs, Int[44, -70, 14, -32, 18]);
```
Let's see what we get for the mean
```julia
julia> mean(myobs)
-5.2
```
So apparently the package handles the above issue.

How does it do it? Basically it applies a heuristic for setting a resonable type for the mean. It creates an array (or number) of the same dimensionality as a measurement and takes, depending on wether the element type is real or complex, either the type `Float64` or `ComplexF64` as element type for the mean. For the above example we can check this, `typeof(mean(myobs)) == Float64`.

## `meantype` keyword

The above heuristic should be reasonable for most cases. However, if it isn't you can set the type of the mean explicitly via the keyword `meantype`. Example:

```julia
julia> myobs = Observable(Int, "My Observable", meantype=Float32);

julia> add!(myobs, Int[44, -70, 14, -32, 18]);

julia> typeof(mean(myobs)) == Float32
```