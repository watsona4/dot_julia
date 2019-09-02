using LinearAlgebra
using MultivariateSeries

X = @ring x1 x2

n = length(X)
d = 4
r = 3

w0  = rand(r)
Xi0 = rand(Float64, n,r)
println("w0=",w0, "   Xi0=",Xi0)
s0 = series(w0, Xi0, X, d)

w, Xi = decompose(s0)
println("w=",w, "     Xi=",Xi)

eps = 1.e-1
w  += eps*rand(Float64, length(w))
Xi += eps*rand(Float64, size(Xi))
println("w=",w, "     Xi=",Xi)

w, Xi = vdm_newton(w, Xi, s0, monoms(X,d), eps=1.e-10, maxit=25)
println("w=",w, "     Xi=",Xi)

s = series(w, Xi, X, d)
println("Error: ", norm(s-s0,Inf))
