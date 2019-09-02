using MultivariateSeries

X = @ring x0 x1 x2 
n = length(X)
d = 4
r = 4

Xi = rand(n,r)
w = fill(1.0,r)
T = tensor(w,Xi,X, d)

k = 2
H = hankel(T,k)
P = perp(T,k)

@assert length(P)==2

