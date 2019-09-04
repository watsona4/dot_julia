
__precompile__()

module TypeStability

    using Compat

    include("StabilityAnalysis.jl")
    include("InlineChecker.jl")
    include("Utils.jl")

end # module
