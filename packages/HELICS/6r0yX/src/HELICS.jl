module HELICS

__precompile__(true)

import Libdl

function __init__()

    LIBRARIES = []

    for library in LIBRARIES
        if Libdl.dlopen(library) == C_NULL
            error("$library cannot be opened. Please check 'deps/build.log' for more information.")
        end
    end

    if Libdl.dlopen(Lib.HELICS_LIBRARY) == C_NULL
        error("$(Lib.HELICS_LIBRARY) cannot be opened. Please check 'deps/build.log' for more information.")
    end

end

include("lib.jl")
include("wrapper.jl")

include("utils.jl")

include("api.jl")


end # module
