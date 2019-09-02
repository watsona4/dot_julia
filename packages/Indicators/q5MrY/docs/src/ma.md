# Moving Averages

## Example

```@example
using Temporal, Indicators, Plots
X = quandl("CHRIS/CME_CL1", rows=252, sort='d')
x = cl(X)
x.fields[1] = :Crude

mafuns = [sma, ema, wma, trima]
m = hcat([f(x, n=40) for f in mafuns]...)

plot(x, linewidth=3, color=:black)
plot!(m, linewidth=2)
savefig("ma_example.svg")  # hide
```
![](ma_example.svg)


## Reference

```@autodocs
Modules = [Indicators]
Pages = ["ma.jl"]
```
