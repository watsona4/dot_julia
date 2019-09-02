import LinearAlgebra
import SparseArrays
@LinearAdjoints.assemblesparsematrix (d,) x function diagonal(d)
	I = Int[]
	J = Int[]
	V = Float64[]
	for i = 1:length(d)
		LinearAdjoints.addentry(I, J, V, i, i, d[end - i + 1])
	end
	return SparseArrays.sparse(I, J, V)
end
d = randn(10)
A = diagonal(d)
@test A == SparseArrays.sparse(LinearAlgebra.Diagonal(reverse(d)))#test that it is still assembling correctly
x = rand(10)
A_px = diagonal_px(x, d)
for i = 1:length(d)
	@test A_px[i, length(d) - i + 1] == x[length(d) - i + 1]
end
