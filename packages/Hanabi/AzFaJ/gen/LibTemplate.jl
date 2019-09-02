module LibHanabi

import Libdl

# Load in `deps.jl`, complaining if it does not exist
const depsjl_path = joinpath(@__DIR__, "..", "deps", "deps.jl")
if !isfile(depsjl_path)
    error("LibHanabi was not build properly. Please run Pkg.build(\"LibHanabi\").")
end
include(depsjl_path)
# Module initialization function
function __init__()
    check_deps()
end

using CEnum

include("ctypes.jl")
export Ctm, Ctime_t, Cclock_t

include(joinpath(@__DIR__, "..", "gen", "libhanabi_common.jl"))
include(joinpath(@__DIR__, "..", "gen", "libhanabi_api.jl"))

# export everything

function camel_to_underscore(s)
    replace(s, r"[A-Z]" => x -> "_" * lowercase(x))[2:end]
end

foreach(names(@__MODULE__, all=true)) do s
    if startswith(string(s), "Py")
        s_type = Symbol(string(s)[3:end])
        @eval begin
            const $s_type = $s
            export $s_type
        end
    elseif match(r"([A-Z][a-z]*)+", string(s)) !== nothing
        s_func = Symbol(camel_to_underscore(string(s)))
        @eval begin
            const $s_func = $s
            export $s_func
        end
    end
end

end # module
