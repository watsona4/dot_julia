@everywhere include("parallel-binomial.jl")
using PyPlot

n = 100
p = 0.5
reps = 1000
rounds = 1000

println("Starting computation")
tic()
c = parallel_binomial_counts(n,p,reps,rounds)
toc()

a = minimum(keys(c))
b = maximum(keys(c))
s = sum(c)

x = collect(a:b)
y = [c[t]/s for t in x]

bar(x,y)
grid()
title("Binomial distribution B($n, $p)")
savefig("binomial.pdf")
