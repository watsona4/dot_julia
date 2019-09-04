module ViZDoom

using CxxWrap
@wrapmodule(joinpath(@__DIR__, "..", "deps", "usr", "ViZDoom-1.1.6", "bin", "libvizdoomjl.so"), :ViZDoom)

function __init__()
    @initcxx
end

include("util.jl")
export get_scenario_path, set_game

include("games/games.jl")
export basic_game

end # module
