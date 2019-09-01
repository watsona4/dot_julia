module AbstractFeedbackNets

using ..Splitters
using ..Mergers

export AbstractFeedbackNet, splitnames, namesvalid

"""
    AbstractFeedbackNet

Abstract base type for networks that include handling for feedback.

# Interface

Any subtype should support iteration (over its layers) in order for the generic
method of this type to work.
"""
abstract type AbstractFeedbackNet end

"""
    splitnames(net::AbstractFeedbackNet)

Return the names of all `Splitter`s in `net`.
"""
function splitnames(net::AbstractFeedbackNet)
    names = Vector{String}()
    for layer in net
        if layer isa Splitter
            push!(names, splitname(layer))
        end
    end
    return names
end # function splitnames

"""
    namesvalid(net::AbstractFeedbackNet)

Check if the input names of all `Mergers` in `net` have a corresponding `Splitter`
and that no two `Splitter`s have the same name.
"""
function namesvalid(net::AbstractFeedbackNet)
    splitters = splitnames(net)
    # check that splitter names are unique
    uniqueness = (length(unique(splitters)) == length(splitters))
    # check that merger names have corresponding splitter name
    mergers = Vector{String}()
    for layer in net
        if layer isa Merger
            push!(mergers, inputname(layer))
        end
    end
    all(name in splitters for name in mergers) & uniqueness
end # function namesvalid

end # module AbstractFeedbackNets
