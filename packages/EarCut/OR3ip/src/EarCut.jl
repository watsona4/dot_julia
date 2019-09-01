module EarCut

using GeometryTypes

const depsfile = joinpath(@__DIR__, "..", "deps", "deps.jl")

if isfile(depsfile)
    include(depsfile)
else
    error("EarCut not build correctly. Please run Pkg.build(\"EarCut\")")
end

function __init__()
    check_deps()
end

include("cwrapper.jl")

export triangulate

end # module
