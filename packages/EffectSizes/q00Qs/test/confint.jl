using EffectSizes
using Test
using EffectSizes: bootstrapsample, twotailedquantile, AbstractConfidenceInterval,
    ConfidenceInterval, BootstrapConfidenceInterval

@testset "AbstractConfidenceInterval" begin
    l = .1
    u = .9
    q = .95
    ci = ConfidenceInterval(l, u, q)
    @test confint(ci) == (l, u)
    @test lower(ci) == l
    @test upper(ci) == u
    @test quantile(ci) == q
    io = IOBuffer()
    show(io, ci)
    @test String(take!(io)) == "$(q)CI ($l, $u)"
    @test_throws DomainError ConfidenceInterval(1, -1, .95)
    @test_throws DomainError ConfidenceInterval(1., 0.999, .95)

    @testset "ConfidenceInterval" begin
        l = .1
        u = .9
        q = .95
        ci = ConfidenceInterval(l, u, q)
        @test confint(ci) == (l, u)
        @test lower(ci) == l
        @test upper(ci) == u
        @test quantile(ci) == q
        io = IOBuffer()
        show(io, ci)
        @test String(take!(io)) == "$(q)CI ($l, $u)"
        @test_throws DomainError ConfidenceInterval(1, -1, .95)
        @test_throws DomainError ConfidenceInterval(1., 0.999, .95)
        @test_throws DomainError ConfidenceInterval(l, u, -0.1)
        @test_throws DomainError ConfidenceInterval(l, u, 1.1)

        xs = randn(90)
        ys = randn(110)
        es = 0.2
        q = 0.9
        ci = ConfidenceInterval(xs, ys, es, quantile=q)
        @test ci isa AbstractConfidenceInterval
        @test quantile(ci) == q
        @test lower(ci) < upper(ci)
        @test ci == ConfidenceInterval(xs, ys, es, quantile=q)
        ci2 = ConfidenceInterval(xs, ys, es, quantile=0.8)
        @test ci !== ci2
        @test lower(ci2) > lower(ci)
        @test upper(ci2) < upper(ci)
        @test_throws DomainError ConfidenceInterval(xs, ys, es, quantile=1.1)
    end

    @testset "BootstrapConfidenceInterval" begin
        l = .1
        u = .9
        q = .95
        b = 10^4
        ci = BootstrapConfidenceInterval(l, u, q, b)
        @test confint(ci) == (l, u)
        @test lower(ci) == l
        @test upper(ci) == u
        @test quantile(ci) == q
        @test ci.bootstrap == b
        io = IOBuffer()
        show(io, ci)
        @test String(take!(io)) == "$(q)CI ($l, $u)"
        @test_throws DomainError BootstrapConfidenceInterval(1, -1, q, b)
        @test_throws DomainError BootstrapConfidenceInterval(1., 0.999, q, b)
        @test_throws DomainError BootstrapConfidenceInterval(l, u, -0.1, b)
        @test_throws DomainError BootstrapConfidenceInterval(l, u, 1.1, b)
        @test_throws DomainError BootstrapConfidenceInterval(l, u, q, -1)

        xs = randn(90)
        ys = randn(110)
        q = 0.8
        f(xs, ys) = sum([sum(xs), sum(ys)] ./ 1000)
        ci = BootstrapConfidenceInterval(xs, ys, f, 100, quantile=q)
        @test ci isa AbstractConfidenceInterval
        @test quantile(ci) == q
        @test lower(ci) < upper(ci)
        @test_throws DomainError BootstrapConfidenceInterval(xs, ys, f, 100, quantile=1.1)
        @test_throws DomainError BootstrapConfidenceInterval(xs, ys, f, -1, quantile=q)
    end
end

@testset "bootstrapsample" begin
    for _ = 1:100
        xs = rand(100)
        ys = bootstrapsample(xs)
        @test length(ys) == length(xs)
        @test Set(ys) ≤ Set(xs)
    end
end

@testset "twotailedquantile" begin
    l, u = twotailedquantile(.95)
    @test l ≈ 0.025
    @test u ≈ 0.975
    @test l + u == 1

    l, u = twotailedquantile(.9)
    @test l ≈ 0.05
    @test u ≈ 0.95
    @test l + u == 1

    for q = rand(100)
        l, u = twotailedquantile(q)
        @test l + u == 1
    end

    @test_throws DomainError twotailedquantile(-.1)
    @test_throws DomainError twotailedquantile(1.1)
end
