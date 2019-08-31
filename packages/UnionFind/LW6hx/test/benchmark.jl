function time_unit(t)
    units = ["hr", "min", "s", "ms", "us", "ns", "ps"]
    sizes = [60.0 * 60.0, 60.0, 1.0, 1e-3, 1e-6, 1e-9, 1e-12]

    for (unit, size) in zip(units, sizes)
        if t / 10 > size
            return unit, size
        end
    end

    return units[end], sizes[end]
end

function fmt_time(ts)
    avg = sum(ts) / length(ts)
    unit, size = time_unit(avg)
    
    return @sprintf "%d %s" (avg / size) unit
end

function bench_graph_union(nodes :: Int, edges :: Int)
    us = [convert(Int, floor(nodes * rand()) + 1) for e in 1:edges]
    vs = [convert(Int, floor(nodes * rand()) + 1) for e in 1:edges]

    uf = UnionFinder(nodes)
    t = @elapsed union!(uf, us, vs)

    return uf, t
end

function bench_grid_union(nodes :: Int, edges :: Int)
    width = convert(Int, ceil(sqrt(nodes)))

    us = [convert(Int, floor(nodes * rand()) + 1) for e in 1:edges]
    
    dirs = [1, nodes - 1, width, nodes - width]
    vs = [(dirs[convert(Int, floor(4 * rand()) + 1)] + us[e]) % nodes + 1
          for e in 1:edges]

    uf = UnionFinder(nodes)
    t = @elapsed union!(uf, us, vs)

    return uf, t
end

function bench_avg(nodes :: Int, frac :: Float64, sweeps :: Int, f :: Function)
    uts = Vector{Float64}(undef, sweeps)
    cts = Vector{Float64}(undef, sweeps)
    
    edges = convert(Int, ceil(nodes * frac))
    
    for i in 1:sweeps
        uf, uts[i] = f(nodes, edges)
        cts[i] = @elapsed CompressedFinder(uf)
        
        uts[i] = edges == 0 ? uts[i] : uts[i] / edges
        cts[i] = cts[i] / nodes
    end
    
    @printf "%12s/edge %12s/node\n" fmt_time(uts) fmt_time(cts)
end

function benchmark_main()
    @printf "%30s%17s %17s\n" " " "UnionFinder" "CompressedFinder"
    
    @printf "%30s" "Sparse 1,000 node graph"
    bench_avg(1000, 0.1, 1000, bench_graph_union)
    @printf "%30s" "Dense 1,000 node graph"
    bench_avg(1000, 0.8, 1000, bench_graph_union)
    @printf "%30s" "Sparse 1,000,000 node graph"
    bench_avg(1000 * 1000, 0.1, 10, bench_graph_union)
    @printf "%30s" "Dense 1,000,000 node graph"
    bench_avg(1000 * 1000, 0.8, 10, bench_graph_union)
    println()
    @printf "%30s" "Sparse 1,000 node grid"
    bench_avg(1000, 0.1, 1000, bench_grid_union)
    @printf "%30s" "Dense 1,000 node grid"
    bench_avg(1000, 0.8, 1000, bench_grid_union)
    @printf "%30s" "Sparse 1,000,000 node grid"
    bench_avg(1000 * 1000, 0.1, 10, bench_grid_union)
    @printf "%30s" "Dense 1,000,000 node grid"
    bench_avg(1000 * 1000, 0.8, 10, bench_grid_union)
end

benchmark_main()
