module NumberIntervals

using IntervalArithmetic

# three-value logic
include("indeterminate.jl")
# basic type definitions, conversion rules, etc
include("types.jl")

# import set-like (IEEE conform) behaviors from IntervalArithmetic
include("set_operations.jl")
include("numeric.jl")
include("boolean.jl")
include("basic.jl")

# define strict number-like arithmetic
include("nonstandard.jl")

end # module
