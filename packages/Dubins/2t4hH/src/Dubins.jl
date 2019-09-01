isdefined(Base, :__precompile__) && __precompile__()

module Dubins

using Memento
using Compat


import Compat: @__MODULE__

const LOGGER = getlogger(@__MODULE__)
setlevel!(LOGGER, "info")

__init__() = Memento.register(LOGGER)

include("typedefs.jl")
include("paths.jl")
include("path_fcns.jl")

end
