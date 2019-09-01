using DumbCompleter
using Test

const DC = DumbCompleter

module Foo
module Bar
export x
const x = 1
end
end

@testset "DumbCompleter.jl" begin
    @testset "modkey" begin
        @test DC.modkey(Foo) == :Foo
        @test DC.modkey(Foo.Bar) == Symbol("Foo.Bar")
        @test DC.modkey(Main.Foo.Bar) == Symbol("Foo.Bar")
        @test DC.modkey(Module(:Foo)) == :Foo
        @test DC.modkey(Module(Symbol("Foo.Bar"))) == Symbol("Foo.Bar")
        @test DC.modkey(Module(Symbol("Main.Foo.Bar"))) == Symbol("Foo.Bar")
    end

    @testset "cancomplete" begin
        s = gensym()
        eval(:($s = 1))
        @test !DC.cancomplete(s, @__MODULE__)
        @test !DC.cancomplete(:abcdefg, Base)
        @test DC.cancomplete(:one, Base)
        @test DC.cancomplete(Symbol("@pure"), Base)
        @test DC.cancomplete(:π, Base)
    end

    @testset "putleaf!" begin
        tr = DC.Tree()
        ab = DC.Leaf(:ab, "foo", Main)
        DC.putleaf!(tr, ab)
        @test tr.tr['a'].tr['b'].lf == ab

        abcd = DC.Leaf(:abcd, "bar", Main)
        DC.putleaf!(tr, abcd)
        @test tr.tr['a'].tr['b'].lf == ab
        @test tr.tr['a'].tr['b'].tr['c'].tr['d'].lf == abcd
    end

    @testset "loadmodule!" begin
        empty!(DC.EXPORTS[].tr)
        empty!(DC.MODULES[])
        DC.loadmodule!(Base)

        tr = DC.EXPORTS[]
        @test tr.tr['o'].tr['n'].tr['e'].lf.name === :one
        @test !haskey(tr.tr['_'].tr, 'o')

        tr = DC.MODULES[][:Base]
        @test tr.tr['o'].tr['n'].tr['e'].lf.name === :one
        @test tr.tr['_'].tr['o'].tr['n'].tr['e'].lf.name === :_one
    end

    @testset "leaves" begin
        DC.loadmodule!(Base)
        nlvs = length(DC.leaves(DC.MODULES[][:Base]))
        nns = length(filter(DC.cancomplete(Base), names(Base; all=true, imported=true)))
        @test nlvs == nns
    end

    @testset "completions" begin
        @test isempty(DC.completions("foo", "bar"))
        @test isempty(DC.completions("one", Core))
        ns = map(lf -> lf.name, DC.completions("one", Base))
        @test Set(ns) == Set([:one, :ones, :oneunit])
        ns = map(lf -> lf.name, DC.completions("show"))
        @test Set(ns) == Set([:show, :showable, :showerror])
    end

    @testset "activate!" begin
        path = dirname(@__DIR__)
        DC.activate!(path)
        @test haskey(DC.MODULES[], :DumbCompleter)
        @test !isempty(DC.MODULES[][:DumbCompleter].tr)
        @test length(DC.completions("ioserver")) == 1
        @test haskey(DC.MODULES[], :JSON)
        @test !isempty(DC.MODULES[][:JSON].tr)
        @test length(DC.completions("json")) == 1
    end

    @testset "Submodule loading" begin
        DC.loadmodule!(Foo)
        @test haskey(DC.MODULES[], DC.modkey(Foo)) &&
            haskey(DC.MODULES[], DC.modkey(Foo.Bar))
        @test !any(lf -> lf.mod === Foo.Bar, DC.completions("x"))
        @test isempty(DC.completions("x", Foo))
        @test length(DC.completions("x", Foo.Bar)) == 1
    end
end
