# Bobby.jl benchmark

```julia
using PkgBenchmark
bmr = benchmarkpkg("Bobby")
export_markdown("bm_results.md", bmr)
```