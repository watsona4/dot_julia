using InterpolatedPDFs
using Test

import Random.seed!
seed!(1234)

@testset "linear_1d" begin

    @testset "UnitRange knots" begin
        x = 0:10
        d = fit_cpl(x, 10.0.*rand(10))
        @test get_knots(d) == x

        @test iszero(cdf(d, first(x)))
        @test isone(cdf(d, last(x)))

        @test quantile(d,0) == first(x)
        @test quantile(d,1) == last(x)
    end

    @testset "StepRangeLen knots" begin
        x = range(0, stop=5, length=10)
        d = fit_cpl(x, 5.0.*rand(10))
        @test get_knots(d) == x

        @test iszero(cdf(d, first(x)))
        @test isone(cdf(d, last(x)))

        @test quantile(d,0) == first(x)
        @test quantile(d,1) == last(x)
    end

    @testset "Vector knots" begin
        x = [0.0, 0.5, 1.0, 1.5, 2.0]
        d = fit_cpl(x, 2.0.*rand(10))
        @test get_knots(d) == x

        @test iszero(cdf(d, first(x)))
        @test isone(cdf(d, last(x)))

        @test quantile(d,0) == first(x)
        @test quantile(d,1) == last(x)
    end

    @testset "pdf cdf quantile check" begin
        x = [0.0, 0.5, 1.0, 1.5, 2.0]
        d = fit_cpl(x, 2.0.*rand(10))

        y = 0.2
        @test isa(pdf(d,y), Float64)
        @test isa(cdf(d,y), Float64)
        @test isa(quantile(d,y), Float64)

        n = 10
        y = pdf(d,2.0.*rand(n))
        @test isa(y, Vector{Float64})
        @test length(y) == n

        y = cdf(d,2.0.*rand(n))
        @test isa(y, Vector{Float64})
        @test length(y) == n

        y = quantile(d,rand(n))
        @test isa(y, Vector{Float64})
        @test length(y) == n
    end

    @testset "error check" begin
        @test_throws ErrorException fit_cpl([0], rand(10))

        @test_throws ErrorException fit_cpl([1,2,3], 3.0.*rand(10))

        @test_throws ErrorException fit_cpl([0,1,2], 3.0.*rand(10))

        @test_throws ErrorException fit_cpl([0,2,1], 2.0.*rand(10))
    end

    @testset "accuracy check" begin
        x = range(0, stop=π/2, length=20)
        d = fit_cpl(x, acos.(rand(100000)))
        xmid = InterpolatedPDFs.midpoints(x)
        @test maximum(abs.(pdf(d,xmid) .- sin.(xmid))) < 0.02
    end

    @testset "sampling" begin
        x = range(0, stop=π/2, length=10)
        d = fit_cpl(x, acos.(rand(100)))
        s = rand(d,100)
        @test minimum(s) ≥ first(x)
        @test maximum(s) ≤ last(x)
        @test isa(s,Vector{Float64})

        s = rand(d,10,10)
        @test isa(s,Matrix{Float64})

        s = rand(d,5,4,3)
        @test isa(s,Array{Float64,3})
    end
end
