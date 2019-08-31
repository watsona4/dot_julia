@testset "Assign bin labels" begin
    D = 3
    E = embed([rand(30) for i = 1:D])
    npts = size(E.points, 2)

    @testset "ϵ is an Int" begin
        labels = assign_bin_labels(E, 10)
        @test size(labels, 1) == D
        @test size(labels, 2) == npts
    end

    @testset "ϵ is a Float64" begin
        labels = assign_bin_labels(E, 0.2)
        @test size(labels, 1) == D
        @test size(labels, 2) == npts
    end

    @testset "ϵ is a Vector{Float64}" begin
        labels = assign_bin_labels(E, [0.2, 0.3, 0.1])
        @test size(labels, 1) == D
        @test size(labels, 2) == npts
    end

    @testset "ϵ is a Vector{Int}" begin
        labels = assign_bin_labels(E, [3, 4, 2])
        @test size(labels, 1) == D
        @test size(labels, 2) == npts
    end
end

@testset "Marginal visitation frequency" begin
    o = rand(100, 3)
    x, y = o[:, 1], o[:, 2]
    E = embed([x, y], [2, 2, 1], [1, 0, 0])
    n_bins = [4, 3, 4]
    # Which bins get visited by every point of the orbit?
    visited_bins_inds = assign_bin_labels(E, n_bins)
    along_which_axes = [1, 2]
    m = marginal_visitation_freq(along_which_axes, visited_bins_inds)

    @test sum(m) ≈ 1
end

@testset "Simplex triangulation" begin
    n_pts = 30
	@testset "Triangulation" begin
        E_3D = embed([rand(n_pts) for i = 1:3])
        E_4D = embed([rand(n_pts) for i = 1:4])

        T_3D = triangulate(E_3D)
        @test typeof(T_3D) <: AbstractTriangulation

        T_4D = triangulate(E_4D)
        @test typeof(T_4D) <: AbstractTriangulation
    end

    @testset "LinearlyInvariantTriangulation" begin
        E_3D = invariantize(embed([rand(n_pts) for i = 1:3]))
        E_4D = invariantize(embed([rand(n_pts) for i = 1:4]))

        T_3D = triangulate(E_3D)
        @test typeof(T_3D) == LinearlyInvariantTriangulation

        T_4D = triangulate(E_4D)
        @test typeof(T_4D) == LinearlyInvariantTriangulation

    end
end
