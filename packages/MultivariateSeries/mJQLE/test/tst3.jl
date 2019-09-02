using MultivariateSeries

X = @ring x1 x2 
n = length(X)
r = 5

L = monoms(X,5)

Xi0 = rand(2,r)
w0  = rand(r)

sigma = series(w0, Xi0, L)

w, Xi = decompose(sigma)

sigma1 = series(w, Xi, L)

@assert norm(sigma-sigma1)<1.e-6


