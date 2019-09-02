module PlanarConvexHullsTest

using PlanarConvexHulls
using StaticArrays
using Test
using Random
using LinearAlgebra
using Statistics

using PlanarConvexHulls: vertex_order

const Point{T} = SVector{2, T}

@testset "is_ordered_and_strongly_convex" begin
    @test is_ordered_and_strongly_convex([Point(1, 2)], CCW)
    @test is_ordered_and_strongly_convex([Point(1, 2), Point(3, 4)], CCW)
    @test is_ordered_and_strongly_convex([Point(1, 2), Point(3, 4), Point(2, 4)], CCW)
    @test !is_ordered_and_strongly_convex([Point(1, 2), Point(3, 4), Point(2, 3)], CCW) # on a line

    v1 = Point(0, 0)
    v2 = Point(1, 0)
    v3 = Point(1, 1)
    v4 = Point(0, 1)
    vertices = [v1, v2, v3, v4]
    for i in 0 : 4
        shifted = circshift(vertices, i)
        @test is_ordered_and_strongly_convex(shifted, CCW)
        @test !is_ordered_and_strongly_convex(reverse(shifted), CCW)
        @test is_ordered_and_strongly_convex(reverse(shifted), CW)
    end

    for i in eachindex(vertices)
        for j in eachindex(vertices)
            if i != j
                vertices′ = copy(vertices)
                vertices′[i] = vertices[j]
                vertices′[j] = vertices[i]
                @test !is_ordered_and_strongly_convex(vertices′, CCW)
            end
        end
    end
end

@testset "area" begin
    @test area(ConvexHull{CCW}(SVector((SVector(1, 1),)))) == 0

    @test area(ConvexHull{CCW}(SVector(SVector(1, 1), SVector(2, 3)))) == 0

    triangle = ConvexHull{CCW}(SVector(Point(1, 1), Point(2, 1), Point(3, 3)))
    @test area(triangle) == 1.0

    square = ConvexHull{CCW}(SVector(Point(1, 1), Point(4, 1), Point(4, 3), Point(1, 3)))
    @test area(square) == 3 * 2
end

@testset "in" begin
    @testset "point" begin
        rng = MersenneTwister(1)
        p = SVector(1, 1)
        C = ConvexHull{CCW}(SVector((p,)))
        @test p ∈ C
        @test Float64.(p) ∈ C
        for i in 1 : 10
            @test p + SVector(randn(rng), randn(rng)) ∉ C
        end
    end

    @testset "line segment" begin
        p1 = SVector(1, 1)
        p2 = SVector(3, 5)
        linesegment = ConvexHull{CCW}([p1, p2])
        @test p1 ∈ linesegment
        @test p2 ∈ linesegment
        @test div.(p1 + p2, 2) ∈ linesegment
        @test p1 + 2 * (p2 - p1) ∉ linesegment
    end

    @testset "triangle" begin
        rng = MersenneTwister(1)
        triangle = ConvexHull{CCW}(SVector(Point(1, 1), Point(2, 1), Point(3, 3)))
        for p in vertices(triangle)
            @test p ∈ triangle
        end
        for i = 1 : 100_000
            weights = normalize(rand(rng, SVector{3}), 1)
            p = reduce(+, vertices(triangle) .* weights)
            @test p ∈ triangle
        end
    end

    @testset "rectangle" begin
        rng = MersenneTwister(1)
        width = 4
        height = 3
        origin = Point(2, 4)
        rectangle = ConvexHull{CCW}(map(x -> x + origin, SVector(Point(0, 0), Point(width, 0), SVector(width, height), SVector(0, height))))
        for p in vertices(rectangle)
            @test p ∈ rectangle
        end
        for i = 1 : 100_000
            p = origin + SVector(width * rand(rng), height * rand(rng))
            @test p ∈ rectangle
        end
        for i = 1 : 10
            p = origin + SVector(width * rand(rng), height * rand(rng))
            @test setindex(p, origin[1] + width + rand(rng), 1) ∉ rectangle
            @test setindex(p, origin[1] - rand(rng), 1) ∉ rectangle
            @test setindex(p, origin[2] + height + rand(rng), 2) ∉ rectangle
            @test setindex(p, origin[2] - rand(rng), 2) ∉ rectangle
        end
    end
end

@testset "centroid" begin
    @testset "point" begin
        p = Point(1, 2)
        @test centroid(ConvexHull{CCW}([p])) === Float64.(p)
    end

    @testset "line segment" begin
        p1 = SVector(1, 1)
        p2 = SVector(3, 5)
        linesegment = ConvexHull{CCW}([p1, p2])
        @test centroid(linesegment) == Point(2.0, 3.0)
    end

    @testset "triangle" begin
        triangle = ConvexHull{CCW}(SVector(Point(1, 1), Point(2, 1), Point(3, 3)))
        @test centroid(triangle) ≈ mean(vertices(triangle)) atol=1e-15
    end
end

function convex_hull_alg_test(hull_alg!)
    @testset "random $order" for order in [CCW, CW]
        hull = ConvexHull{order, Float64}()
        rng = MersenneTwister(2)
        for n = 1 : 10
            sizehint!(hull, n) # just to get code coverage
            for _ = 1 : 10_000
                points = [rand(rng, Point{Float64}) for i = 1 : n]
                hull_alg!(hull, points)
                @test is_ordered_and_strongly_convex(vertices(hull), order)
            end
        end
    end

    @testset "collinear input $order" for order in [CCW, CW]
        hull = ConvexHull{order, Float64}()
        points = [Point(0., 0.), Point(0., 1.), Point(0., 2.), Point(1., 0.), Point(1., 1.), Point(1., 2.)]
        for i = 1 : 10
            shuffle!(points)
            hull_alg!(hull, points)
            @test is_ordered_and_strongly_convex(vertices(hull), order)
            @test isempty(symdiff(vertices(hull), [Point(0., 0.), Point(1., 0.), Point(1., 2.), Point(0., 2.)]))
        end
    end

    @testset "numerical problem $order" for order in [CCW, CW]
        hull = ConvexHull{order, Float64}()
        points = Point{Float64}[
            [-0.17559141363793285, 0.1777893970092983],
            [-0.17574071124767324, 0.04921003844438379],
            [0.08480367424885946, 0.17745906024313485],
            [0.08465437663911904, 0.04887970167822034],
            [-0.13059226250542266, 0.17773231116261107],
            [-0.13074156011516305, 0.04915295259769656],
            [-0.1753504285942606, -0.1772960226863406],
            [-0.1756647405301049, -0.04875022362480264],
            [0.08503864201675085, -0.17672638211747324],
            [0.08472433008090652, -0.04818058305593528],
            [-0.13035231731355584, -0.17719758249586814],
            [-0.13066662924940015, -0.04865178343433017]]
        hull_alg!(hull, points)
        @test is_ordered_and_strongly_convex(vertices(hull), order)
    end
end

@testset "jarvis_march!" begin
    convex_hull_alg_test(jarvis_march!)
end

@testset "closest_point $order" for order in [CCW, CW]
    hull = ConvexHull{order, Float64}()
    rng = MersenneTwister(3)
    for n = 1 : 10
        for _ = 1 : 100
            points = [rand(rng, Point{Float64}) for i = 1 : n]
            jarvis_march!(hull, points)

            for point in vertices(hull)
                closest = closest_point(point, hull)
                @test closest == point
            end

            for _ = 1 : 100
                point = rand(rng, Point{Float64})
                closest = closest_point(point, hull)
                if point ∈ hull
                    @test closest == point
                else
                    closest_to_closest = closest_point(closest, hull)
                    @test closest_to_closest ≈ closest atol=1e-14
                end
            end
        end
    end

    # visualize = true
    # if visualize
    #     flush(stdout)
    #     hull = ConvexHull{CCW, Float64}()
    #     rng = MersenneTwister(3)
    #     n = 5
    #     points = [rand(rng, Point{Float64}) for i = 1 : n]
    #     jarvis_march!(hull, points)
    #     projections = map(1 : 1_000_000) do _
    #         closest_point(rand(rng, Point{Float64}), hull)
    #     end
    #     plt = scatterplot(getindex.(projections, 1), getindex.(projections, 2))
    #     scatterplot!(plt, getindex.(vertices(hull), 1), getindex.(vertices(hull), 2), color = :red)
    #     display(plt)
    # end
end

function make_oversized(A::AbstractMatrix, b::AbstractVector)
    n = length(b)
    n_oversized = n + 1
    similar(A, (n_oversized, 2)), similar(b, n_oversized)
end

function make_oversized(A::SMatrix, b::SVector{n}) where n
    n_oversized = n + 1
    similar(A, Size(n_oversized, 2)), similar(b, Size(n_oversized))
end

function hreptest(hull::H, rng) where {H<:ConvexHull}
    A, b = hrep(hull)
    A_oversized, b_oversized = make_oversized(A, b)
    hrep!(A_oversized, b_oversized, hull)
    for _ = 1 : 100
        testpoint = rand(rng, Point{Float64})
        @test (testpoint ∈ hull) == all(A * testpoint .<= b) == all(A_oversized * testpoint .<= b_oversized)
    end
    if Length(vertices(hull)) !== Length{StaticArrays.Dynamic()}()
        @test(@allocated(hrep(hull)) == 0)
    end
end

@testset "hrep $order" for order in [CCW, CW]
    dynamichull = ConvexHull{order, Float64}()
    rng = MersenneTwister(4)
    for n = 2 : 10
        for _ = 1 : 100
            points = [rand(rng, Point{Float64}) for i = 1 : n]
            jarvis_march!(dynamichull, points)
            hreptest(dynamichull, rng)

            h = num_vertices(dynamichull)
            statichull = ConvexHull{order}(SVector{h}(vertices(dynamichull)))
            hreptest(statichull, rng)
        end
    end
end

struct CustomPoint{T} <: FieldVector{2, T}
    x::T
    y::T
end

@testset "Constructors" begin
    width = 4
    height = 3
    origin = Point(2, 4)
    verts = map(x -> x + origin, [Point(0, 0), Point(width, 0), SVector(width, height), SVector(0, height)])
    rectangle = ConvexHull{CW}(reverse(verts))

    srectangle = SConvexHull{4, Float64}(rectangle)
    drectangle = DConvexHull{Float64}(rectangle)
    @test vertices(srectangle) isa SVector{4}
    @test vertices(drectangle) isa Vector
    for hull in [srectangle, drectangle]
        @test vertex_order(hull) == CCW
        @test eltype(hull) == Float64
        @test is_ordered_and_strongly_convex(vertices(hull), vertex_order(hull))
    end

    let hull = ConvexHull{CCW, Float64}(verts)
        @test vertices(hull) == verts
        @test eltype(hull) == Float64
    end
    let hull = ConvexHull{CCW, Float64, CustomPoint{Float64}}(verts)
        @test vertices(hull) == verts
        @test eltype(hull) == Float64
        @test typeof(vertices(hull)) == Vector{CustomPoint{Float64}}
    end
    let hull = ConvexHull{CCW, Float64, Point{Float64}, SVector{4, Point{Float64}}}(verts)
        @test vertices(hull) == verts
        @test eltype(hull) == Float64
        @test typeof(vertices(hull)) == SVector{4, SVector{2, Float64}}
    end

    @test isempty(vertices(DConvexHull{Float64}()))
end

@testset "benchmarks" begin
    include(joinpath("..", "perf", "runbenchmarks.jl"))
end

end # module
