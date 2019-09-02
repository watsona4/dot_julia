using MultivariateSeries
X = @ring x0 x1 x2
d = 4
F = (x0+x1+x2)^d + 1.5*(x0+x1)^d -2.0*(x0-x2)^d
w, Xi = decompose(F)
F1 = tensor(w, Xi, X, d)
@assert norm(F-F1)<1.e-6

