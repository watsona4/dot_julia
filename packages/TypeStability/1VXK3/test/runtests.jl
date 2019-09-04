using TypeStability
using Compat
using Compat.Test

@testset "TypeStability.jl" begin

    include("StabilityAnalysisTests.jl")
    include("InlineCheckerTests.jl")
    include("Utils.jl")
end
