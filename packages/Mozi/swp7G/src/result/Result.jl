module Result

using ..FEStructure
using ..LoadCase

include("../util/mmp.jl")

include("./nodal_result.jl")
include("./beam_result.jl")
include("./quad_result.jl")
include("./tria_result.jl")

include("./modal_result.jl")

end
