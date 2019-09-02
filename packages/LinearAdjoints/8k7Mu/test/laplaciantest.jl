import SparseArrays
@LinearAdjoints.assemblesparsematrix (k,) x function laplacian(k, n)
	I = Int[]
	J = Int[]
	V = Float64[]
	for i = 1:n - 1
		LinearAdjoints.addentry(I, J, V, i, i, -2 * k)
		LinearAdjoints.addentry(I, J, V, i + 1, i, 1 * k)
		LinearAdjoints.addentry(I, J, V, i, i + 1, 1 * k)
	end
	LinearAdjoints.addentry(I, J, V, n, n, -2 * k)
	return SparseArrays.sparse(I, J, V)
end
n = 10
A = laplacian(pi, n)
@test A == SparseArrays.spdiagm(-1=>fill(pi, n - 1), 0=>fill(-2 * pi, n), 1=>fill(pi, n - 1))
x = rand(10)
A_px = laplacian_px(x, pi, n)
@test A_px[1, 1] == -2 * x[1] + x[2]
@test A_px[1, end] == -2 * x[end] + x[end - 1]
for i = 2:n - 1
	@test A_px[1, i] == x[i - 1] - 2 * x[i] + x[i + 1]
end
