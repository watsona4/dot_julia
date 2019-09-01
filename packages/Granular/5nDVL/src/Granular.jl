#!/usr/bin/env julia
"""
# Granular.jl
Offline granular dynamics simulator module.
"""
module Granular

include("datatypes.jl")
include("grain.jl")
include("simulation.jl")
include("grid.jl")
include("packing.jl")
include("contact_search.jl")
include("interaction.jl")
include("temporal.jl")
include("temporal_integration.jl")
include("io.jl")
include("ocean.jl")
include("atmosphere.jl")
include("util.jl")
include("wall.jl")

end # module end
