module MangalTestNodes
    using Mangal
    using Test
    include("setup.jl")

    @test typeof(nodes()) <: Vector{MangalNode}

    n1 = node(2158)
    @test typeof(n1) <: MangalNode
    @test typeof(n1.taxon) <: MangalReferenceTaxon

    b1 = backbone(1)
    nb1 = nodes(b1)
    @test first(nb1).taxon == b1

end
