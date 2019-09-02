using MultivariateSeries

X = @ring x1 x2
L = monoms(X,5)

Xi0 = rand(2,3)
w0 = rand(3)

sigma = series(w0, Xi0, L)

w, Xi = decompose(sigma, cst_rkf(3))
