using EffectSizes, Statistics
using Test
using EffectSizes: AbstractEffectSize, correction, pooledstd1, pooledstd2

@testset "$T constructor" for (T, v) = [(EffectSize, :d), (CohenD, :d), (HedgeG, :g),
                                        (GlassΔ, :Δ)]
    e = 0.
    l = -1.
    u = 1.
    q = .95
    es = T(e, ConfidenceInterval(l, u, q))
    @test es isa AbstractEffectSize
    @test effectsize(es) == getfield(es, v)
    @test confint(es) == es.ci
    @test quantile(es) == es.ci.quantile
    @test lower(es.ci) == es.ci.lower
    @test upper(es.ci) == es.ci.upper
    io = IOBuffer()
    show(io, es)
    @test String(take!(io)) == "$e, $(q)CI ($l, $u)"

    xs = randn(90)
    ys = randn(110)

    @test effectsize(T(xs .+ 1, xs)) > 0
    @test effectsize(T(xs, xs .+ 1)) < 0

    @testset "constructors" begin
        # Normal
        es = T(xs, ys)
        @test quantile(es) == 0.95
        @test typeof(effectsize(es)) == eltype(xs)
        @test es == T(xs, ys)

        @test effectsize(T(xs, xs)) == 0

        es2 = T(xs, ys, quantile=0.8)
        @test lower(confint(es2)) > lower(confint(es))
        @test upper(confint(es2)) < upper(confint(es))
        @test quantile(es2) == 0.8
        @test effectsize(es2) == effectsize(es)

        # bootstrap
        es3 = T(xs, ys, 100)
        @test effectsize(es3) == effectsize(es)
        @test quantile(es3) == 0.95

        es4 = T(xs, ys, 100, quantile=0.1)
        @test quantile(es4) == 0.1
        @test lower(confint(es3)) < lower(confint(es4))
        @test upper(confint(es3)) > upper(confint(es4))

        @test effectsize(T(xs, xs, 100)) == 0
    end
end

@testset "correction" begin
    @test_throws DomainError correction(1)
    @test correction(2) == 0.
    @test correction(20) > .9
    @test correction(10^9) ≈ 1
end

@testset "effectsize" begin
    # from http://staff.bath.ac.uk/pssiw/stats2/page2/page14/page14.html
    @test round(effectsize(20., 24., 4.53), digits=3) == -0.883

    xs = 10:110
    ys = 1:100
    mx = mean(xs)
    my = mean(ys)
    s = pooledstd1(xs, ys)
    @test effectsize(mx, my, s, 100) > effectsize(mx, my, s, 50) > effectsize(mx, my, s, 10)
end
