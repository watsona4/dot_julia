using Test, DependenciesParser

@testset "Base Test" begin
    for pkg ∈ DependenciesParser.data
        @inferred installable(pkg)
        deps = installable(pkg)
        @test last(installable(DependenciesParser.data[1], direct = true)) ⊆ last(deps)
        first(deps) && break
    end
end
