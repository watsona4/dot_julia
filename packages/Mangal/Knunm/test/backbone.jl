module MangalTestBackbone
    using Mangal
    using Test
    include("setup.jl")

    # Backbone only
    @test typeof(backbones()) <: Vector{MangalReferenceTaxon}

    @test typeof(backbones("q" => "Salix")) <: Vector{MangalReferenceTaxon}

    @test backbone(1).name == "Abutilon theophrasti"
    @test backbone("Abutilon theophrasti").id == 1

    @test length(backbones(Pair("count", 10))) == 10

end
