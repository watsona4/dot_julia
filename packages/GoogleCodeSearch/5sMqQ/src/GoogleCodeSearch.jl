module GoogleCodeSearch

using BinaryProvider
using Sockets
using JSON
using HTTP

import Base: show
export Ctx, index, search, show, indices, clear_indices, paths_indexed, run_http

const depsjl_path = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if !isfile(depsjl_path)
    error("GoogleCodeSearch not installed properly, run Pkg.build(\"GoogleCodeSearch\"), restart Julia and try again")
end
include(depsjl_path)
include("codesearch.jl")
include("server.jl")

end # module
