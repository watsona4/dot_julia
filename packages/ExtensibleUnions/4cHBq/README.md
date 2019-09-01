# ExtensibleUnions

[![Bors enabled](https://bors.tech/images/badge_small.svg)](https://app.bors.tech/repositories/20023)
[![Build Status](https://travis-ci.com/bcbi/ExtensibleUnions.jl.svg?branch=master)](https://travis-ci.com/bcbi/ExtensibleUnions.jl/branches)
[![Codecov](https://codecov.io/gh/bcbi/ExtensibleUnions.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/bcbi/ExtensibleUnions.jl)

```julia
julia> import Pkg; Pkg.add("ExtensibleUnions")
```

ExtensibleUnions is an experimental package that adds abstract multiple inheritance to Julia in the
form of extensible type unions.

TODO: Make this package thread-safe.

## Usage

Create a new extensible union:
```julia
struct MyUnion end
extensibleunion!(MyUnion)
```

Add methods that dispatch on extensible unions:
```julia
f(x::MyUnion1, y, z, ...) = ...
f(x, y::MyUnion2, z, ...) = ...
extensiblefunction!(f, MyUnion1, MyUnion2, ...)
```

Add types to an extensible union:
```julia
addtounion!(MyUnion, SomeType1, SomeType2, ...)
```

At any later time, you can add more types to an extensible union:
```julia
addtounion!(MyUnion, SomeType3, SomeType4, ...)
```

## Examples

### Example 1

```julia
julia> using ExtensibleUnions

julia> abstract type AbstractCar end

julia> abstract type AbstractFireEngine end

julia> struct RedCar <: AbstractCar
       end

julia> struct BlueCar <: AbstractCar
           x
       end

julia> struct LadderTruck{T} <: AbstractFireEngine
           x::T
       end

julia> mutable struct WaterTender{T} <: AbstractFireEngine
           x::T
           y::T
       end

julia> struct RedColorTrait end

julia> struct BlueColorTrait end

julia> extensibleunion!(RedColorTrait)
RedColorTrait

julia> extensibleunion!(BlueColorTrait)
BlueColorTrait

julia> describe(x) = "I don't know anything about this object"
describe (generic function with 1 method)

julia> methods(describe)
# 1 method for generic function "describe":
[1] describe(x) in Main at REPL[12]:1

julia> describe(RedCar())
"I don't know anything about this object"

julia> describe(BlueCar(1))
"I don't know anything about this object"

julia> describe(LadderTruck{Int}(2))
"I don't know anything about this object"

julia> describe(WaterTender{Int}(3,4))
"I don't know anything about this object"

julia> describe(x::RedColorTrait) = "The color of this object is red"
describe (generic function with 2 methods)

julia> extensiblefunction!(describe, RedColorTrait)
describe (generic function with 2 methods)

julia> describe(x::BlueColorTrait) = "The color of this object is blue"
describe (generic function with 3 methods)

julia> extensiblefunction!(describe, BlueColorTrait)
describe (generic function with 3 methods)

julia> methods(describe)
# 3 methods for generic function "describe":
[1] describe(x::BlueColorTrait) in Main at REPL[20]:1
[2] describe(x::RedColorTrait) in Main at REPL[18]:1
[3] describe(x) in Main at REPL[12]:1

julia> describe(RedCar())
"I don't know anything about this object"

julia> describe(BlueCar(1))
"I don't know anything about this object"

julia> describe(LadderTruck{Int}(2))
"I don't know anything about this object"

julia> describe(WaterTender{Int}(3,4))
"I don't know anything about this object"

julia> addtounion!(RedColorTrait, RedCar)
RedColorTrait

julia> methods(describe)
# 3 methods for generic function "describe":
[1] describe(x::BlueColorTrait) in Main at REPL[20]:1
[2] describe(x::Union{RedCar, RedColorTrait}) in Main at REPL[18]:1
[3] describe(x) in Main at REPL[12]:1

julia> describe(RedCar())
"The color of this object is red"

julia> describe(BlueCar(1))
"I don't know anything about this object"

julia> describe(LadderTruck{Int}(2))
"I don't know anything about this object"

julia> describe(WaterTender{Int}(3,4))
"I don't know anything about this object"

julia> addtounion!(BlueColorTrait, BlueCar)
BlueColorTrait

julia> methods(describe)
# 3 methods for generic function "describe":
[1] describe(x::Union{RedCar, RedColorTrait}) in Main at REPL[18]:1
[2] describe(x::Union{BlueColorTrait, BlueCar}) in Main at REPL[20]:1
[3] describe(x) in Main at REPL[12]:1

julia> describe(RedCar())
"The color of this object is red"

julia> describe(BlueCar(1))
"The color of this object is blue"

julia> describe(LadderTruck{Int}(2))
"I don't know anything about this object"

julia> describe(WaterTender{Int}(3,4))
"I don't know anything about this object"

julia> addtounion!(RedColorTrait, AbstractFireEngine)
RedColorTrait

julia> methods(describe)
# 3 methods for generic function "describe":
[1] describe(x::Union{BlueColorTrait, BlueCar}) in Main at REPL[20]:1
[2] describe(x::Union{RedCar, RedColorTrait, AbstractFireEngine}) in Main at REPL[18]:1
[3] describe(x) in Main at REPL[12]:1

julia> describe(RedCar())
"The color of this object is red"

julia> describe(BlueCar(1))
"The color of this object is blue"

julia> describe(LadderTruck{Int}(2))
"The color of this object is red"

julia> describe(WaterTender{Int}(3,4))
"The color of this object is red"
```

## Acknowledgements

Much of the code in this package is taken from:
1. https://github.com/NHDaly/DeepcopyModules.jl (license: MIT)
2. https://github.com/perrutquist/CodeTransformation.jl (license: MIT)
