using Statistics, StatsBase
using StructArrays
using Recombinase
using Recombinase: compute_summary, aroundindex, discrete,
    prediction, density
using Test
using IndexedTables
using OnlineStatsBase

@testset "discrete" begin
    x = [1, 2, 3, 1, 2, 3]
    y = [0.3, 0.1, 0.3, 0.4, 0.2, 0.1]
    across = [1, 1, 1, 2, 2, 2]
    res = compute_summary(
        discrete(prediction)(min_nobs = 1),
        across,
        (x, y),
        stats = Mean()
    )
    xcol, ycol = fieldarrays(res)
    @test xcol == [1, 2, 3]
    @test map(Recombinase._first, ycol) ≈ [0.35, 0.15, 0.2]
    res = compute_summary(
        discrete(density),
        across,
        (x,),
        stats = Mean()
    )
    xcol, ycol = fieldarrays(res)
    @test xcol == [1, 2, 3]
    @test map(Recombinase._first, ycol) ≈ [1, 1, 1]./3
end

# example function to test initstats and fitvecmany!
function fitvec(stats, iter, ranges)
    start = iterate(iter)
    start === nothing && error("Nothing to fit!")
    val, state = start
    init = Recombinase.initstats(stats, Recombinase.merge_tups(axes(val), ranges))
    Recombinase.fitvecmany!(init, Iterators.rest(iter, state))
    StructArray(((nobs = nobs(el), value = value(el)) for el in init);
        unwrap = t -> t <: Union{Tuple, NamedTuple})
end

@testset "timeseries" begin
    v1 = rand(1000) # day 1
    v2 = rand(50) # day 2
    traces = [v1, v1, v1, v2, v2, v2]
    ts = [10, 501, 733, 1, 20, 30]
    trims = [7:13, 498:504, 730:736, 1:4, 17:23, 27:33]
    stats = Series(mean = Mean(), variance = Variance())
    s = fitvec(stats, (aroundindex(trace, t) for (trace, t) in zip(traces, ts)), -5:5);
    @test axes(s) == (-5:5,)
    @test s[-3].nobs == 4
    @test s[-3].value isa NamedTuple{(:mean, :variance)}
    s = fitvec(stats, (aroundindex(trace, t, trim) for (trace, t, trim) in zip(traces, ts, trims)), -5:5);
    @test axes(s) == (-5:5,)
    @test s[-3].nobs == 4
    @test s[-3].value isa NamedTuple{(:mean, :variance)}
    @test s[-4].nobs == 0

    stats = Mean()
    s = fitvec(stats, (aroundindex(trace, t) for (trace, t) in zip(traces, ts)), -5:5);
    @test axes(s) == (-5:5,)
    @test s[-3].nobs == 4
    @test s[-3].value isa Float64

    g() = aroundindex(rand(4, 4, 4), (2, 2), (1:3, 1:3))
    @inferred g()
    @test axes(g()) == (-1:1, -1:1, 1:4)
end
