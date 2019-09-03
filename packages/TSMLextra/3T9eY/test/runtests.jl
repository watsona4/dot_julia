module TestTSMLextra
using Test
using TSML
using TSMLextra
using TSMLextra.System

include("test_readerwriter.jl")

if LIB_CRT_AVAILABLE
    include("test_caret.jl")
else
    @info "Skipping CARET tests."
end


if LIB_SKL_AVAILABLE
    include("test_scikitlearn.jl")
else
    @info "Skipping scikit-learn tests."
end

end
