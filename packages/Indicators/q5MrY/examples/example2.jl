# workspace()
using Indicators
using PyPlot
using Base.Dates
using Temporal

aapl = yahoo("AAPL")
aapl = aapl["2015"]

t = aapl.index
aapl = aapl.values
op = aapl[:,1]
hi = aapl[:,2]
lo = aapl[:,3]
cl = aapl[:,4]
vo = aapl[:,5]
hlc = [hi lo cl]

subplot(411)
plot(t, cl, lw=2, c="k", label="AAPL")
plot(t, kama(cl), c="b", label="Kaufman AMA")
plot(t, trima(cl), c="g", label="Triangula MA")
plot(t, hma(cl), c="r", label="Hull MA")
grid(ls="-", c=[0.8,0.8,0.8])
legend(loc="best", frameon=false)

subplot(412)
plot(t, kst(cl), c="m", label="KST")
plot(t, sma(kst(cl),n=9), c="c", label="Signal")
plot([t[1],t[end]], [0,0], ls="--", c=[0.4,0.4,0.4])
grid(ls="-", c=[0.8,0.8,0.8])
legend(loc="best", frameon=false)

subplot(413)
plot(t, wpr(hlc), c=[1,0.5,0], label="Williams %R")
plot([t[1],t[end]], [-20,-20], c="r", ls="--")
plot([t[1],t[end]], [-80,-80], c="g", ls="--")
grid(ls="-", c=[0.8,0.8,0.8])
legend(loc="best", frameon=false)

subplot(414)
plot(t, cci(hlc), c="c", label="CCI")
plot([t[1],t[end]], [-100,-100], c="g", ls="--")
plot([t[1],t[end]], [100,100], c="r", ls="--")
grid(ls="-", c=[0.8,0.8,0.8])
legend(loc="best", frameon=false)

tight_layout()
