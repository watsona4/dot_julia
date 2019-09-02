#__precompile__(true)

## License follows that of https://github.com/eiscor/eiscor
## This codebase is derived in large part from software at https://people.cs.kuleuven.be/~raf.vandebril/
## which (presumably) has found its way into the eiscor code base and released under the MIT license

module AMVW
using LinearAlgebra
import Base: adjoint


#using IntervalArithmetic
#Base.eps{T}(::Type{Interval{T}}) = eps(T)

# package code goes here


include("types.jl")
include("utils.jl")
include("transformations.jl")
include("factorization.jl")
include("diagonal-block.jl")
include("bulge.jl")
include("deflation.jl")
include("AMVW_algorithm.jl")

include("diagnostics.jl")

end # module
