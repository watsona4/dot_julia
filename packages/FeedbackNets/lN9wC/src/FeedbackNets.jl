"""
    FeedbackNets

Implements deep networks with feedback operations from higher to lower layers.
Uses Flux as a backend.
"""
module FeedbackNets
using Reexport

include("Splitters.jl")
include("AbstractMergers.jl")
include("Mergers.jl")
include("AbstractFeedbackNets.jl")
include("FeedbackChains.jl")
include("FeedbackTrees.jl")
include("modelfactory/ModelFactory.jl")
@reexport using .Splitters
@reexport using .AbstractMergers
@reexport using .Mergers
@reexport using .AbstractFeedbackNets
@reexport using .FeedbackChains
@reexport using .FeedbackTrees
@reexport using .ModelFactory

# add definition for dictionaries to Flux._truncate in order to make truncate!
# work states of Recur-ed FeedbackChains and FeedbackTrees
import Flux: _truncate
_truncate(d::Dict) = Dict(key => _truncate(val) for (key, val) in pairs(d))

end # module FeedbackNets
