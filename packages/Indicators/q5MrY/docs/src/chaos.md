# Chaos Theory / Fractals

# Example
```@example
using Temporal, Indicators, Plots
X = quandl("CHRIS/CME_CL1", rows=252, sort='d')
x = cl(X)
x.fields[1] = :Crude

r = [rsrange(x, n=60) rsrange(x, n=60, cumulative=true)]
r.fields = Symbol.(["Rolling R/S", "Cumulative R/S"])
h = [hurst(x, n=60) hurst(x, n=60, cumulative=true)]
h.fields = Symbol.(["Rolling Hurst", "Cumulative Hurst"])

f1 = plot(x, linewidth=3, color=:black)
f2 = plot(r, linewidth=2, color=[:red :darkred], linestyle=[:solid :dash])
f3 = plot(h, linewidth=2, color=[:cyan :darkcyan], linestyle=[:solid :dash])
plot(f1, f2, f3, layout=@layout[a{0.5h}; b{0.25h}; c{0.25h}])
savefig("chaos_example.svg")  # hide
```
![](chaos_example.svg)

## Reference

```@autodocs
modules = [Indicators]
pages = ["chaos.jl"]
```
