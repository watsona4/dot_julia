using Simplices
using Simplices: SimplexSplitting

"""
    intersectiontest(dim::Int, n_reps::Int, intersection_type::String, tolerance::Float64)
Generate a `n_reps` pairs of `dim`-dimensional simplices that intersect in the way specified by `intersecton_type`. Valid intersection types are `"nontrivial"` and `"sharingvertices"`. Checks if the total volume spanned by each pair of simplices matches that obtained when accounting for the shared volume.
"""
function intersectiontest(dim::Int, n_reps::Int, intersection_type::String; tolerance = 1/10^12)

    discrepancies = zeros(Float64, n_reps)
    elapsed = zeros(Float64, n_reps)
    for i = 1:n_reps
        s₁, s₂ = intersecting_simplices(dim = dim, intersection_type = intersection_type)
        before = time_ns()/10^9
        intvol = simplexintersection(copy(transpose(s₁)), copy(transpose(s₂)), tolerance = tolerance, what = "volume")
        after =  time_ns()/10^9
        elapsed[i] = after - before
        vol₁ = volume(s₁)
        vol₂ = volume(s₂)
        total_vol = vol₁ + vol₂
        discrepancies[i] = total_vol - ((vol₁ - intvol) + (vol₂ - intvol) + intvol)
        if discrepancies[i] > 1/10^5
            @show vol₁, vol₂, discrepancies[i]
        end
    end
    return discrepancies, elapsed
end

"""
    intersectiontest(dim::Int, n_reps::Int, intersection_type::String, tolerance::Float64)
Generate a `n_reps` pairs of `dim`-dimensional simplices that intersect in the way specified by `intersecton_type`. Valid intersection types are `"nontrivial"` and `"sharingvertices"`. Checks if the total volume spanned by each pair of simplices matches that obtained when accounting for the shared volume.
"""
function intersectiontest(dim::Int, n_reps::Int, intersection_type::String)

    discrepancies = zeros(Float64, n_reps)
    for i = 1:n_reps
        s₁, s₂ = intersecting_simplices(dim = dim, intersection_type = intersection_type)
        intvol = simplexintersection(copy(transpose(s₁)), copy(transpose(s₂)))
        vol₁ = volume(s₁)
        vol₂ = volume(s₂)
        total_vol = vol₁ + vol₂
        discrepancies[i] = total_vol - (intvol + (vol₁ - intvol) + (vol₂ - intvol) )
        if discrepancies[i] > 1/10^5
            @show s₁, s₂
        end
    end
    return discrepancies
end


# Splits a canonical simplex of dimension E with size division factor k. Inside the simplex,
# it generates a random subsimplex. Compute its volume by computing the intersection of
# that simplex with the simplices forming the splitting of the original simplex. Compare
# the volume obtained by the simplex intersection routine to the analytical volume.
# N is the number of times to perform the test, and tolerance is the usual tolerance in the
# simplex intersection routine.
function nd_Test(k, E, N; tolerance = 1/10^12, plot = false)


    # Define vertices of canonical simplex
    canonical_simplex_vertices = zeros(E + 1, E)
    canonical_simplex_vertices[2:(E+1), :] = Matrix(1.0I, E, E)
    simplex_indices = zeros(Int, 1, E + 1)
    simplex_indices[1, :] = round.(Int, collect(1:E+1))

    refined = refine_triangulation(canonical_simplex_vertices, simplex_indices, [1], k)
    triang_vertices, triang_simplex_indices = refined[1], refined[2]

    differences = zeros(Float64, N)

    # Repeat the test N times
    for i = 1:N
        # Build convex expansion coefficients for the random simplex. We need these in a
        # form that guarantees that the random simplex lies within the canonical simplex.
        beta = rand(E + 1, E + 1)
        beta = beta .* repeat(1 ./ sum(beta, dims = 2), 1, E + 1)
        # Ensure that we have convex expansions

        # Linear combination of the original vertices and the convex expansion coefficients.
        # Creates a matrix containing the vertices of the random simplex (which now is
        # guaranteed to lie _within_ the original simplex.
        random_simplex = beta * canonical_simplex_vertices
        random_simplex_orientation = det(hcat(ones(E + 1), random_simplex))
        random_simplex_volume = abs(random_simplex_orientation)
        random_simplex = copy(transpose(random_simplex))

        # Intersection between each of the subsimplices with the random simplex
        intersecting_volumes = zeros(Float64, size(triang_simplex_indices, 1))

        for j = 1:size(triang_simplex_indices, 1)
            # Get the subsimplex vertices
            subsimplex = copy(transpose(triang_vertices[triang_simplex_indices[j, :], :]))
            intvol = simplexintersection(random_simplex, subsimplex, tol = tolerance)
            intersecting_volumes[j] = intvol
        end

        # Compute the discrepancies
        numeric_volume = sum(intersecting_volumes)
        analytic_volume = random_simplex_volume
        differences[i] = abs((numeric_volume - analytic_volume)/analytic_volume)

    end
    return differences
end

function test_nontrivial(dim,N)
   for i = 1:N
        S1,S2 = nontrivially_intersecting_simplices(dim)
        simplexintersection(copy(transpose(S1)), copy(transpose(S2)))
    end

    return true
end


function test_sharing(dim,N)
    for i = 1:N
        S1,S2 = simplices_sharing_vertices(dim)
        simplexintersection(copy(transpose(S1)), copy(transpose(S2)))
    end
    return true
end

@testset "Nontrivial intersection" begin
    n = 10
    @testset "E = $E" for E in 3:5
        @test test_nontrivial(E, n) == true
    end
end

@testset "Sharing a vertex" begin
    n = 10
    @testset "E = $E" for E in 3:5
        @test test_sharing(E, n) == true
    end
end

@test nd_Test(2, 3, 1)[1] < 1e-8
@test nd_Test(2, 4, 1)[1] < 1e-8
@test nd_Test(2, 5, 1)[1] < 1e-8


@testset "nD discrepancy: strictly contained" begin
    # Trigger precompilation on simplest example
    k = 2; reps = 1
    function init()
        for E = 3
            discrepancies = nd_Test(k, E, reps)
            @test maximum(discrepancies) < 1e-8
        end
    end

    init()

    reps = 10
    # Time more involved examples
    println("nD discrepancy test with ", reps, " reps:")
    @testset "E = $E" for E in 3:5
        # Trigger once for precompilation
        @testset "k = $k" for k in 2:3
            t1 = time_ns()/10^9
            discrepancies = nd_Test(k, E, reps)
            t2 = time_ns()/10^9
            @test maximum(discrepancies) < 1e-8
        end
    end
end
