module FeedbackChains

using Flux
import Flux: children, mapchildren
import Base: getindex, show
using MacroTools: @forward

using ..Splitters
using ..AbstractMergers
using ..AbstractFeedbackNets
export FeedbackChain

"""
    FeedbackChain{T<:Tuple}

Tuple-like structure similar to a Flux.Chain with support for `Splitter`s and `Merger`s.
"""
struct FeedbackChain{T<:Tuple} <: AbstractFeedbackNet
    layers::T
    FeedbackChain(xs...) = new{typeof(xs)}(xs)
end

# empty feedback chain just returns the input
function (c::FeedbackChain{Tuple{}})(h, x)
    return h, x
end # function (c::FeedbackChain{Tuple{}})

"""
    (c::FeedbackChain)(h, x)

Apply a `FeedbackChain` to input `x` with hidden state `h`. `h` should take the
form of a dictionary mapping `Splitter` names to states.
"""
function (c::FeedbackChain)(h, x)
    newh = Dict{String, Any}()
    for layer ∈ c.layers
        if layer isa Splitter
            newh[splitname(layer)] = x
        elseif layer isa AbstractMerger
            x = layer(x, h)
        else
            x = layer(x)
        end
    end
    return newh, x
end # function (c::FeedbackChain)

# These overloads ensure that a FeedbackChain behaves as Flux expects, e.g.,
# when moving to gpu or collecting parameters.
children(c::FeedbackChain) = c.layers
mapchildren(f, c::FeedbackChain) = FeedbackChain(f.(c.layers)...)

# These overloads ensure that indexing / slicing etc. work with FeedbackChains
@forward FeedbackChain.layers Base.getindex, Base.length, Base.first, Base.last,
         Base.iterate, Base.lastindex
getindex(c::FeedbackChain, i::AbstractArray) = FeedbackChain(c.layers[i]...)

function show(io::IO, c::FeedbackChain)
    print(io, "FeedbackChain(")
    join(io, c.layers, ", ")
    print(io, ")")
end # function show
end # module FeedbackChains
