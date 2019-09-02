using Indicators
using PyPlot
using Base.Dates

# Generate some toy sample data
srand(1)
n = 250
op = 100.0 + cumsum(randn(n))
hi = op + rand(n)
lo = op - rand(n)
cl = 100.0 + cumsum(randn(n))
for i = 1:n
	if cl[i] > hi[i]
		cl[i] = hi[i]
	elseif cl[i] < lo[i]
		cl[i] = lo[i]
	end
end
ohlc = [op hi lo cl]
hlc = [hi lo cl]
hl = [hi lo]
t = collect(today():Day(1):today()+Day(n-1))

# Overlays
subplot(411)
plot(t, cl, lw=2, c="k", label="Random Walk")
grid(ls="-", c=[0.8,0.8,0.8])
plot(t, sma(cl,n=40), c=[1,0.5,0], label="SMA (40)")
plot(t, ema(cl,n=10), c=[0,1,1], label="EMA (10)")
plot(t, wma(cl,n=20), c=[1,0,1], label="WMA (20)")
plot(t, psar(hl),   "bo", label="Parabolic SAR")
legend(loc="best", frameon=false)

# MACD
subplot(412)
plot(t, macd(cl)[:,1], label="MACD", c=[1,0.5,1])
plot(t, macd(cl)[:,2], label="Signal", c=[0.5,0.25,0.5])
bar(t, macd(cl)[:,3], align="center", label="Histogram", color=[0,0.5,0.5], alpha=0.25)
plot([t[1],t[end]], [0,0], ls="--", c=[0.5,0.5,0.5])
grid(ls="-", c=[0.8,0.8,0.8])
legend(loc="best", frameon=false)

# RSI
subplot(413)
plot(t, rsi(cl), c=[0.5,0.5,0], label="RSI")
grid(ls="-", c=[0.8,0.8,0.8])
plot([t[1],t[end]], [30,30], c="g")
plot([t[1],t[end]], [70,70], c="r")
legend(loc="best", frameon=false)

# ADX
subplot(414)
plot(t, adx(hlc)[:,1], "g-", label="DI+")
plot(t, adx(hlc)[:,2], "r-", label="DI-")
plot(t, adx(hlc)[:,3], c=[0,0,1], lw=2, label="ADX")
grid(ls="-", c=[0.8,0.8,0.8])
legend(loc="best", frameon=false)

tight_layout()
