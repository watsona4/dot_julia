"""
    ModelFactory

A collection of functions to generate the feedback networks and baseline models
used in evaluations and examples.
"""
module ModelFactory
using Reexport

include("Flatten.jl")
@reexport using .Flatten

include("LRNs.jl")
@reexport using .LRNs

include("LeNet5.jl")
@reexport using .LeNet5

include("Spoerer2017.jl")
@reexport using .Spoerer2017

end # module ModelFactory
