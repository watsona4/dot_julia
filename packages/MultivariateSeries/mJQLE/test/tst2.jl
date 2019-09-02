using MultivariateSeries

r  = 4
w0 = rand(r)
A0 = rand(5,r)
B0 = rand(3,r)
C0 = rand(4,r)

T0 = tensor(w0, A0, B0, C0)
w, A, B, C = decompose(T0, eps_rkf(1.e-10), mode=2)

T = tensor(w, A, B, C)
@assert norm(T-T0)< 1.e-6
