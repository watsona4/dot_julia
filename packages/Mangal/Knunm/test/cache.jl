module MangalTestCache
    using Mangal
    using Test
    include("setup.jl")

    # random node
    N = nodes()[1]

    n = node(N.id)

    @test length(Mangal._MANGAL_CACHES[MangalNode]) != 0

end
