@testset "FeedbackChains" begin
    @testset "constructor" begin
        # 1. Can construct a FeedbackChain just like a normal chain.
        c = FeedbackChain(Dense(10, 5), relu)
        @test length(c.layers) == 2
        # 2. Can construct a FeedbackChain with forkers and mergers
        c = FeedbackChain(Merger("f1", identity, +), Dense(10, 10, relu), Splitter("f1"), Dense(10, 1))
        @test length(c.layers) == 4
    end # @testset "constructor"

    @testset "apply" begin
        h = Dict("f1"=>randn(10))
        x = randn(10)
        # apply empty chain
        c = FeedbackChain()
        @test c(h, x) == (h, x)
        # apply FeedbackChain without feedback
        c = FeedbackChain(x -> (2.0 .* x), x -> relu.(x), x -> x'x)
        state, y = c(Dict(), x)
        @test y ≈ relu.(2.0 .* x)'relu.(2.0 .* x)
        @test state isa Dict{String, Any}
        # apply feedback chain with feedback
        l1 = Dense(10, 10, relu)
        l2 = Dense(10, 1)
        c = FeedbackChain(Merger("f1", identity, +), l1, Splitter("f1"), l2)
        state, y = c(h, x)
        @test y ≈ l2(l1(h["f1"] + x))
        @test haskey(state, "f1")
        @test state["f1"] ≈ l1(h["f1"] + x)
    end # @testset "apply"

    @testset "params" begin
        l1 = Dense(10, 10)
        l2 = Dense(7, 10)
        c = FeedbackChain(l1, l2)
        @test hcat(params(c)...) == hcat(params(l1)..., params(l2)...)
    end # @testset "params"

    @testset "recur" begin
        h = Dict("f1"=>randn(10))
        x = randn(10)
        l1 = Dense(10, 10, relu)
        l2 = Dense(10, 1)
        c = FeedbackChain(Merger("f1", identity, +), l1, Splitter("f1"), l2)
        c = Flux.Recur(c, h)
        y = c(x)
        @test y ≈ l2(l1(h["f1"] + x))
        @test haskey(c.state, "f1")
        @test c.state["f1"] ≈ l1(h["f1"] + x)
        # check that truncation works
        @test Flux.Tracker.istracked(c.state["f1"])
        Flux.truncate!(c)
        @test !Flux.Tracker.istracked(c.state["f1"])
        # check that reset works
        Flux.reset!(c)
        @test c.state["f1"] == c.init["f1"]
    end # @testset "recur"

    @testset "indexing" begin
        c = FeedbackChain(Dense(1,2), Dense(2,3), Dense(3,1))
        @test c[1] == c.layers[1]
        @test c[2:3] == FeedbackChain(c.layers[2:3]...)
    end # @testset "indexing"

    @testset "iteration" begin
        c = FeedbackChain(Dense(1,2), Dense(2,3), Dense(3,1))
        layers = [layer for layer in c]
        @test layers == collect(c.layers)
    end # @testset "iteration"

    @testset "interface" begin
        # test that generic method `splitname` works
        c = FeedbackChain(
            Splitter("name1"),
            Merger("name2", nothing, +),
            Splitter("name3"),
            Dense(10,10)
        )
        @test splitnames(c) == ["name1", "name3"]
        # test that validation of naming works
        @test !namesvalid(c) # merger name does not fit splitter names
        c = FeedbackChain(Splitter("name1"), Merger("name1", nothing, +))
        @test namesvalid(c)
        c = FeedbackChain(Splitter("name1"), Splitter("name1"))
        @test !namesvalid(c)
    end # @testset "interface"
end # @testset "FeedbackChains"
