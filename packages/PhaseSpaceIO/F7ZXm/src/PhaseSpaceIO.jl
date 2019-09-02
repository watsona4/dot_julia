__precompile__()
module PhaseSpaceIO
using ArgCheck
using DataStructures
using Requires

include("abstract.jl")
include("iohelpers.jl")
include("common.jl")
include("iaea/iaea.jl")
include("egs/egs.jl")
include("api.jl")
include("experimental.jl")
include("getters.jl")
include("testing.jl")
include("deprecate.jl")
include("download.jl")
include("conversion.jl")

function __init__()
    @require StaticArrays="90137ffa-7385-5640-81b9-e52037218182" begin
        include("staticarrays.jl")
        @require CoordinateTransformations="150eb455-5306-5404-9cee-2592286d6298" begin
            include("transforms.jl")
        end
    end
end

end#module
