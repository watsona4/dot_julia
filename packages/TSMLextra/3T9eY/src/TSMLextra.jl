module TSMLextra

using Reexport

@reexport using TSML

include("system.jl")
using .System

include("datareader.jl")
using .DataReaders

include("datawriter.jl")
using .DataWriters

if LIB_CRT_AVAILABLE # from System module
    include("caret.jl")
    using .CaretLearners
end

if LIB_SKL_AVAILABLE # from System module
    include("scikitlearn.jl")
    using .SKLearners
end

end # module
