module ChartParsers

using DataStructures: SortedSet

export Arc,
       lhs,
       rhs,
       rule,
       constituents,
       score,
       ChartParser,
       AbstractGrammar,
       AbstractRule,
       is_complete,
       BottomUp,
       TopDown,
       SimpleRule,
       SimpleWeightedRule,
       SimpleGrammar,
       SimpleWeightedGrammar

# function push(x::AbstractVector{T}, y::T) where {T}
#     result = copy(x)
#     push!(result, y)
#     result
# end

# function push(x::NTuple{N, T}, y::T) where {N, T}
#     tuple(x..., y)
# end

include("LayeredVectors.jl")
using .LayeredVectors
include("arc.jl")
include("grammar.jl")
include("chart.jl")
include("parser.jl")

end # module
