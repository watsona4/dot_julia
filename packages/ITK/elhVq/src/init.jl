# Load in `deps.jl`, complaining if it does not exist
const depsjl_path = joinpath(@__DIR__, "..", "deps", "deps.jl")
if !isfile(depsjl_path)
    println("Deps path: $depsjl_path")
    error("ITK not installed properly, run `] build ITK`, restart Julia and try again")
end

include(depsjl_path)
