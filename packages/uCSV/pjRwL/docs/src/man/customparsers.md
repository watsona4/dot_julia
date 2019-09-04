# Custom Parsers

You can declare any parser function that takes `T <: AbstractString` and returns a Julia value.

Your custom parsers can be applied to specific columns
```julia
using uCSV, DataFrames
function myparser(x)
    # code
end
my_input = ...
uCSV.read(my_input, colparsers=Dict(column => x -> myparser(x)))
```

You can also declare the relevant column-types and implement parsers specific to that type
```julia
using uCSV, DataFrames
function myparser(x)
    # code
end
my_input = ...
uCSV.read(my_input, types=Dict(1 => MyType), typeparsers=Dict(MyType => x -> myparser(x)))
```
