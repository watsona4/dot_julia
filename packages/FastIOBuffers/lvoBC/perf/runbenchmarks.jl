module FastIOBuffersBenchmarks

using Random
using BenchmarkTools
using FastIOBuffers

const N = 1000

suite = BenchmarkGroup()

suite["write"] = BenchmarkGroup()
suite["write"]["Float64"] = @benchmarkable write(buf, x) evals = N setup = begin
    x = rand(Float64)
    buf = FastWriteBuffer(Vector{UInt8}(undef, N * Core.sizeof(x)))
end
suite["write"]["String"] = @benchmarkable write(buf, x) evals = N setup = begin
    x = randstring(8)
    buf = FastWriteBuffer(Vector{UInt8}(undef, N * sizeof(x)))
end

suite["read"] = BenchmarkGroup()
suite["read"]["Float64"] = @benchmarkable read(buf, Float64) evals = N setup = begin
    rng = MersenneTwister(1)
    writebuf = IOBuffer()
    map(1 : N) do _
        write(writebuf, rand(rng, Float64))
    end
    buf = FastReadBuffer(take!(writebuf))
end
suite["read"]["String"] = @benchmarkable (seekstart(buf); read(buf, String)) setup = begin
    rng = MersenneTwister(1)
    writebuf = IOBuffer()
    write(writebuf, randstring(rng, N))
    buf = FastReadBuffer(take!(writebuf))
end

overhead = BenchmarkTools.estimate_overhead()
results = run(suite, verbose=true, overhead=overhead, gctrial=false)

for result in results["write"]
    println("$(first(result)):")
    display(last(result))
    println()
end
for result in results["read"]
    println("$(first(result)):")
    display(last(result))
    println()
end

end
