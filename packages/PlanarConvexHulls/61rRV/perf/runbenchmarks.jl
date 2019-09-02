import Pkg
Pkg.activate(@__DIR__)

using BenchmarkTools
using PlanarConvexHulls
using StaticArrays
using Random

const T = Float64

suite = BenchmarkGroup()

for n in [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000]
    rng = MersenneTwister(n)
    hull = ConvexHull{CCW, T}()
    sizehint!(hull, n)
    suite["jarvis_march! $n"] = @benchmarkable jarvis_march!($hull, points) setup = begin
        points = [rand($rng, SVector{2, T}) for _ = 1 : $n]
    end
end

overhead = BenchmarkTools.estimate_overhead()
results = run(suite, verbose=true, overhead=overhead, gctrial=false)
for result in results
    println("$(first(result)):")
    display(last(result))
    println()
end
