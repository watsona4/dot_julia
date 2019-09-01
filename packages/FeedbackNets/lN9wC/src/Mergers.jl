module Mergers

import Flux: children, mapchildren
import Base: show

using ..AbstractMergers

export Merger, inputname

"""
    Merger{F,O}

An element in a `FeedbackChain` in which the forward stream and feedback stream
are combined according to an operation `op`.

# Fields
- `splitname::String`: name of the `Splitter` node from which the feedback is taken
- `fb::F`: feedback branch
- `op::O`: operation to combine forward and feedback branches

# Details
`fb` typically takes the form of a Flux operation or chain. When a `FeedbackChain`
encounters a `Merger`, it will look up the state `s` of the `Splitter` given by `forkname`
from the previous timestep, apply `fb` to it and combine it with the forward input `x`
according  to `op(x, fb(s))`
"""
struct Merger{F,O} <: AbstractMerger
    splitname::String
    fb::F
    op::O
end # struct Merger

function (m::Merger)(x, y)
    m.op(x, m.fb(y[m.splitname]))
end

# These overloads ensure that a Merger behaves as Flux expects, e.g.,
# when moving to gpu or collecting parameters.
children(m::Merger) = (m.fb, m.op)
mapchildren(f, m::Merger) = Merger(m.splitname, f(m.fb), m.op)

"""
    inputname(m::Merger)

Return the name of the `Splitter` from which `m` gets its input.
"""
inputname(m::Merger) = m.splitname

function show(io::IO, m::Merger)
    print(io, "Merger(\"", m.splitname, "\", ", m.fb, ", ", m.op, ")")
end # function show
end # module Mergers
