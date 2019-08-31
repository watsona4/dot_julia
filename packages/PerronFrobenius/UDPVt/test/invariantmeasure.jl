tol = 1e-13
@testset "Invariant measures" begin

    @testset "Grid estimator" begin
        points_2D = rand(2, 200)
        points_3D = rand(3, 400)
        E_2D = invariantize(embed(points_2D))
        E_3D = invariantize(embed(points_3D))
        ϵ = 3
        bins_visited_by_orbit_2D = assign_bin_labels(E_2D, ϵ)
        bins_visited_by_orbit_3D = assign_bin_labels(E_3D, ϵ)

        bininfo_2D = organize_bin_labels(bins_visited_by_orbit_2D)
        bininfo_3D = organize_bin_labels(bins_visited_by_orbit_3D)

        TO_2D = transferoperator_binvisits(bininfo_2D)
        TO_3D = transferoperator_binvisits(bininfo_3D)

        invm_2D = left_eigenvector(TO_2D)
        invm_3D = left_eigenvector(TO_3D)

        @test all(invm_2D.dist .>= -tol)
        @test sum(invm_2D.dist) <= 1 + tol || sum(invm_2D.dist) ≈ 1
    end

    @testset "Triangulation approximate estimator" begin
        E = embed([diff(rand(15)) for i = 1:3])
        E_invariant = invariantize(E)

        # Triangulations
        triang = triangulate(E)
        triang_inv = triangulate(E_invariant)

        # Transfer operators from *invariant* triangulations
        TO = transferoperator_triang(triang_inv)
        TO_approx = transferoperator_triang(triang_inv, exact = false, parallel = false)
        TO_approx_rand = transferoperator_triang(triang_inv, exact = false, parallel = false, sample_randomly = true)
        invm_approx = left_eigenvector(TO_approx)
        invm_approx_rand = left_eigenvector(TO_approx_rand)

        @test all(invm_approx.dist .>=  -tol)
        @test all(invm_approx_rand.dist .>= -tol)

        @test sum(invm_approx.dist) ≈ 1
        @test sum(invm_approx_rand.dist) ≈ 1
    end

    @testset "RectangularInvariantMeasure" begin
        E = embed([diff(rand(100)) for i = 1:5])
        ϵ = 3
        # On raw points
        @test typeof(RectangularInvariantMeasure(E.points, 3)) <: InvariantMeasure
        @test typeof(RectangularInvariantMeasure(E.points, 0.4)) <: InvariantMeasure
        @test typeof(RectangularInvariantMeasure(E.points, [3, 2, 2, 3, 2])) <: InvariantMeasure
        @test typeof(RectangularInvariantMeasure(E.points, [0.6, 0.5, 0.6, 0.5, 0.6])) <: InvariantMeasure

        # On embeddings
        @test typeof(RectangularInvariantMeasure(E, 3)) <: InvariantMeasure
        @test typeof(RectangularInvariantMeasure(E, 0.4)) <: InvariantMeasure
        @test typeof(RectangularInvariantMeasure(E, [3, 2, 2, 3, 2])) <: InvariantMeasure
        @test typeof(RectangularInvariantMeasure(E, [0.6, 0.5, 0.6, 0.5, 0.6])) <: InvariantMeasure
        @show RectangularInvariantMeasure(E.points, 3)

	end
end
