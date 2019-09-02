module MangalTestInteractions

    using Mangal
    using Test

    @test typeof(interactions()) <: Vector{MangalInteraction}
    @test typeof(interactions(Pair("type", "mutualism"))) <: Vector{MangalInteraction}

    @test typeof(interactions(:, node(31863))) <: Vector{MangalInteraction}
    @test typeof(interactions(node(31904), :)) <: Vector{MangalInteraction}

    @test typeof(interactions(:, node(31863), Pair("type", "predation"))) <: Vector{MangalInteraction}
    @test typeof(interactions(node(31904), :, Pair("type", "predation"))) <: Vector{MangalInteraction}

    @test typeof(interactions(node(31904), node(31863))) <: Vector{MangalInteraction}
    @test typeof(interactions(node(31904), node(31863), Pair("type", "predation"))) <: Vector{MangalInteraction}

end
