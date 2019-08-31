"Testing and specification"
module Spec

using Cassette
import Pkg
import Random

include("specs.jl")         # Specifications
include("pre.jl")          # Preconditions
include("testing.jl")      # Testing Tools

export @pre,
       @with_pre,
       with_pre,
       @post,
       @invariant,
       walktests,
       @spec

end
