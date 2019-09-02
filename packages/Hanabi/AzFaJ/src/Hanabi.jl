module Hanabi

using Reexport

include(joinpath(@__DIR__, "..", "gen", "LibTemplate.jl"))
@reexport using .LibHanabi

end # module