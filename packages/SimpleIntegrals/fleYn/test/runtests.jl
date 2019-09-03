using SimpleIntegrals
using SimpleIntegrals: trapezoid
using Test
using InteractiveUtils: subtypes

@testset "spike" begin
    xs = [0,1,2]
    ys = [0,1,0]
    @test trapezoid(xs,ys) ≈ 1
    @test trapezoid(xs,ys, 0, 1) ≈ 0.5
    @test trapezoid(xs,ys, 1, 2) ≈ 0.5
    @test trapezoid(xs,ys, 0.1, 1) ≈ 0.5 - 0.1^2/2
    @test trapezoid(xs,ys, 0., 0.9) ≈ 0.9^2/2
    a,b = sort!(rand(2))
    a = 0.1; b =0.9
    @test trapezoid(xs,ys, a,b) ≈ (b-a) * (b+a) /2
end

@testset "constant function" begin
    for _ in 1:100
        n = rand(1:10)
        xs = sort!(randn(n))
        c = randn()
        ys = fill(c, size(xs))
        @test trapezoid(xs, ys) ≈ c * (last(xs) - first(xs))

        a,b = extrema(xs)
        @test trapezoid(xs,ys) ≈ trapezoid(xs,ys,a,b)

        w1,w2 = sort!(rand(2))
        a = minimum(xs) + w1 * (maximum(xs) - minimum(xs))
        b = minimum(xs) + w2 * (maximum(xs) - minimum(xs))
        @test trapezoid(xs,ys,a,b) ≈ c * (b-a)
    end
end

@testset "edgecases" begin
    @test trapezoid(Float64[], Float64[]) === 0.
    @test trapezoid(Float64[1], Float64[1],1,1) === 0.
end

function random_xs_ys(T,n)
    random(T,n) = T.(randn(n))
    xs = sort!(random(T,n))
    ys = random(T,n)
    xs, ys
end

@testset "pasting" begin
    for _ in 1:100
        n1 = rand(1:10)
        n2 = rand(1:10)
        xs1, ys1 = random_xs_ys(Float64,n1)
        xs2, ys2 = random_xs_ys(Float64,n2)
        xs2 .= xs2 .- first(xs2) .+ last(xs1)
        @assert first(xs2) == last(xs1)
        @test trapezoid(xs1,ys1) + trapezoid(xs2, ys2) ≈
            trapezoid([xs1;xs2], [ys1;ys2])
    end
    for _ in 1:100
        n = rand(1:10)
        xs,ys = random_xs_ys(Float64, n)
        w1,w2,w3 = sort!(rand(3))
        a = minimum(xs) + w1 * (maximum(xs) - minimum(xs))
        b = minimum(xs) + w2 * (maximum(xs) - minimum(xs))
        c = minimum(xs) + w3 * (maximum(xs) - minimum(xs))
        @test trapezoid(xs,ys,a,b) + trapezoid(xs,ys,b,c) ≈
            trapezoid(xs,ys,a,c)
    end
end

@testset "typestability" begin
    for T in subtypes(AbstractFloat)
        xs, ys = random_xs_ys(T,0)
        @inferred trapezoid(xs, ys)
        @test T == typeof(trapezoid(xs,ys))

        xs, ys = random_xs_ys(T,2)
        a = b = first(xs)
        @inferred trapezoid(xs, ys, a, b)
        @test T == typeof(trapezoid(xs, ys, a, b))
    end
end

@testset "api" begin
    xs, ys = random_xs_ys(Float64,10)
    @test trapezoid(xs,ys) == integral(xs,ys)
    a,b = extrema(xs)
    @test trapezoid(xs,ys,a,b) == integral(xs,ys, window=(a,b))
end

@testset "Range and Vector consistent" begin
    for _ in 1:100
        xs = range(randn(), length=rand(2:30), step=10rand())
        ys = randn(length(xs))
        @test integral(xs, ys) ≈ integral([xs;],ys)
        w1,w2= sort!(rand(2))
        a = minimum(xs) + w1 * (maximum(xs) - minimum(xs))
        b = minimum(xs) + w2 * (maximum(xs) - minimum(xs))
        @test integral(xs, ys, window=(a,b)) ≈ integral([xs;],ys, window=(a,b))
    end
end
