@testset "Mergers" begin
    splitname = "splittestname"
    fbop = x -> 0.5 .* x.^2
    combineop = (x, y) -> x + σ.(y)
    m = Merger(splitname, fbop, combineop)
    x = randn(5)
    y = randn(5)
    h = Dict(splitname => y)

    @testset "constructor" begin
        @test m isa Merger{typeof(fbop), typeof(combineop)}
        @test m.splitname == splitname
        @test m.fb(x) ≈ fbop(x)
        @test m.op(x, y) ≈ combineop(x, y)
    end # @testset "constructor"

    @testset "apply" begin
        @test m(x, h) ≈ m.op(x, m.fb(y))
    end # @testset "apply"

    @testset "params" begin
        # Test that a Merger returns the parameters of its internal operations
        fb = Dense(10, 5)
        op = Chain((x, y) -> hcat(x, y), Dense(10, 5))
        m = Merger(splitname, fb, op)
        @test hcat(params(m)...) == hcat(params(fb)..., params(op)...)
    end # @testset "params"

    @testset "children" begin
        @test Flux.children(m) == (m.fb, m.op)
        m2 = Flux.mapchildren(x -> nothing, m)
        @test m2.splitname == m.splitname
        @test m2.fb == nothing
        @test m2.op == m.op
    end # @testset "children"

    @testset "name" begin
        @test inputname(m) == splitname
    end # @testset "name"
end # @testset "Mergers"
