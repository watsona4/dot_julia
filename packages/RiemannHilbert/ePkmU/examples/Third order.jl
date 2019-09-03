using ApproxFun

M = 50
d₋, d₊ = -M .. 0, 0 ..M
D = Derivative()

V₋ = Fun(x -> sech(x), d₋)
V₊ = Fun(x -> sech(x), d₊)

# ψ'' + (V(x) + k^2) ψ = 0

k = 0.0001

ψ = [ivp(); D^2  + (V₋ + k^2)] \ [exp(im*k*(-M)), im*k*(exp(im*k*(-M))), 0.0]
