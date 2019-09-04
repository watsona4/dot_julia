#
# XPA.jl --
#
# Implement XPA communication via the dynamic library.
#
#------------------------------------------------------------------------------
#
# This file is part of XPA.jl released under the MIT "expat" license.
# Copyright (C) 2016-2019, Éric Thiébaut (https://github.com/emmt/XPA.jl).
#

isdefined(Base, :__precompile__) && __precompile__(true)

module XPA

export
    XPA_VERSION

using Base: ENV

# FIXME: constanst should be in deps.jl
if isfile(joinpath(dirname(@__FILE__), "..", "deps", "deps.jl"))
    include(joinpath("..", "deps", "deps.jl"))
else
    error("XPA not properly installed.  Please run Pkg.build(\"XPA\")")
end
include("types.jl")
include("misc.jl")
include("client.jl")
include("server.jl")

end # module
