using TableWidgets, Observables, WebIO, Widgets, InteractBase
using DataFrames
using Test

@testset "selector" begin
    v = [1, 1, 2, 2, 1, 3, 4]
    sel = categoricalselector(v)
    @test observe(sel)[] == v
    observe(sel, :checkboxes)[] = [1, 3]
    sleep(0.1)
    @test observe(sel)[] == [1, 1, 1, 3]

    sel = rangeselector(v)
    @test observe(sel)[] == v
    observe(sel, :extrema)[] = [1.8, 3.2]
    observe(sel, :changes)[] = 4
    sleep(0.1)
    @test observe(sel)[] == [2, 2, 3]

    sel = selector(v, map)
    @test observe(sel)[] == fill(true, length(v))
    observe(sel, :function)[] = t -> t != 2
    observe(sel, :textbox, :changes)[] = 4
    sleep(0.1)
    @test observe(sel)[] == map(t -> t != 2, v)
end

@testset "undo" begin
    obs = Observable(1)
    u = TableWidgets.Undo(obs)
    obs[] = 2
    sleep(0.1)
    @test obs[] == 2
    u()
    sleep(0.1)
    @test obs[] == 1
    @test observe(u)[] == 1
end

@testset "table" begin
    df = DataFrame(x = 1:4, y = ["a", "b", "c", "d"])
    n = Observable(3)
    wdg = TableWidgets.head(df, n)
    l = WebIO.children(WebIO.children(wdg[:head][].dom)[2]) |> length
    @test l == 3
    n[] = 10
    sleep(0.1)
    l = WebIO.children(WebIO.children(wdg[:head][].dom)[2]) |> length
    @test l == 4
end
