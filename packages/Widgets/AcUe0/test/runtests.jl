using Widgets, Observables, OrderedCollections, InteractBase, WebIO
using Colors
using Widgets: Widget, @layout, widgettype
import Widgets: observe, @auto
using Test

@testset "utils" begin
    d = Widget{:test}(Dict(:a => 1, :b => Observable(2), :c => Widget{:test}(; output = Observable(5))))
    m = d[:a] + d[:b][] + d[:c][]
    n = Observables.@map d[:a] + &d[:b] + d[:c][]
    @test m == 8
    @test n[] == 8
    d[:b][] = 3
    sleep(0.1)
    @test m == 8
    @test n[] == 9
    @test isa(Observables.@map(&d[:c]), Observable)

    v = [1]
    t = Widget{:test}(Dict(:a => Observable(2), :b => Observable(50)));
    Observables.@on v[1] += &t[:b]
    observe(t, :b)[] = 15
    sleep(0.1)
    @test v[1] == 16
    observe(t, :b)[] = 30
    sleep(0.1)
    @test v[1] == 46

    d = Widget{:test}(Dict(:a => 1, :b => Observable(2), :c => Widget{:test}(; output = Observable(5))))
    m = d |> @layout :a + :b[]
    n = d |> @layout Observables.@map :a + &(:b)
    @test m == 3
    @test n[] == 3
    d[:b][] = 3
    sleep(0.1)
    @test m == 3
    @test n[] == 4
    @test isa(@layout(d, :c), Widget)
end

function myui(x)
    a = x + 1
    b = Observable(10)
    output = Observables.@map &b + a
    @auto x = "aa"
    Widget{:myui}(
        ["a" => a, "b" => b, "x" => x],
        output = output,
        layout = t -> Observables.@map "The sum is "*string(&t)
    )
end

Widgets.widget(::Val{:myui}, args...; kwargs...) = myui(args...; kwargs...)

@testset "widget" begin
    ui = myui(5)
    @test ui[:a] == 6
    @test ui[:b][] == 10
    @test ui.output[] == 16
    @test ui.layout(ui)[] == "The sum is 16"
    @test widgettype(ui[:x]) == :textbox
    @test observe(ui[:x])[] == "aa"


    ui = Widgets.widget(Val(:myui), 5)
    @test ui[:a] == 6
    @test ui[:b][] == 10
    @test ui.output[] == 16
    @test ui.layout(ui)[] == "The sum is 16"

    ui = Widgets.@nodeps myui(5)
    @test ui[:a] == 6
    @test ui[:b][] == 10
    @test ui.output[] == 16
    @test ui.layout(ui)[] == "The sum is 16"

    ui[:b][] = 11
    sleep(0.1)
    @test ui.output[] == 17
    @test ui.layout(ui)[] == "The sum is 17"
end

@testset "auto" begin
    @auto x = 10
    @test observe(x)[] == 10
    @test widgettype(x) == :spinbox
end

@testset "layout" begin
    wdg = slider(1:100)
    wdg2 = wdg(style = Dict("color" => "red"))
    n = WebIO.render(wdg2)
    @test props(n)[:style]["color"] == "red"
    @test Widgets.node(wdg) isa Node
end

@testset "observable" begin
    t = Widget{:test}(Dict(:a => Observable(2), :b => Observable(50)), output = Observable(12));
    s = map(x->x-1, t)
    @test t[] == 12
    @test s[] == 11
end

@testset "manipulate" begin
    ui = @manipulate for r = 0:.05:1, g = 0:.05:1, b = 0:.05:1
        RGB(r,g,b)
    end
    @test observe(ui)[] == RGB(0.5, 0.5, 0.5)
    observe(ui, :r)[] = 0.1
    sleep(0.1)
    @test observe(ui)[] == RGB(0.1, 0.5, 0.5)
    ui = @manipulate throttle = 1 for r = 0:.05:1, g = 0:.05:1, b = 0:.05:1
        RGB(r,g,b)
    end
    observe(ui, :r)[] = 0.1
    sleep(0.1)
    observe(ui, :r)[] = 0.3
    sleep(0.1)
    observe(ui, :g)[] = 0.1
    sleep(0.1)
    observe(ui, :g)[] = 0.3
    sleep(0.1)
    observe(ui, :b)[] = 0.1
    sleep(0.1)
    observe(ui, :b)[] = 0.3
    sleep(0.1)
    @test observe(ui)[] != RGB(0.3, 0.3, 0.3)
    sleep(1.5)
    @test observe(ui)[] == RGB(0.3, 0.3, 0.3)
end

