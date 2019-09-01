module Splitters

export Splitter, splitname

"""
    Splitter

An element in a `FeedbackChain` that marks locations where a feedback branch forks
off from the forward branch.

# Fields
- `name::String`: unique name used to identify the fork for the backward pass.

# Details
In the forward stream, a is essentially an identity operation. It only alerts the
`FeedbackChain` to add the current Array to the chain's state and mark it with
the Splitters `name` so that `Merger`s can access it for feedback to the next
timestep.
"""
struct Splitter
    name::String
end # struct Splitter

"""
    splitname(s::Splitter)

Return name of `s`.
"""
splitname(s::Splitter) = s.name

end # module Splitters
