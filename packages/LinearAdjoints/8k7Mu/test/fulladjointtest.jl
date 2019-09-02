import FDDerivatives
import SparseArrays
@LinearAdjoints.assemblevector (k, f) b function rhs(k, f)
	n = length(f)
	b = Array{Float64}(undef, length(f))
	for i = 1:length(f)
		b[i] = f[i] / n
	end
	return b
end
@LinearAdjoints.assemblesparsematrix (k, f) x function laplacian(k, f)
	n = length(f)
	I = Int[]
	J = Int[]
	V = Float64[]
	dx = 1 / (n - 1)
	for i = 1:n - 1
		LinearAdjoints.addentry(I, J, V, i, i, -2 * k / dx)
		LinearAdjoints.addentry(I, J, V, i + 1, i, k / dx)
		LinearAdjoints.addentry(I, J, V, i, i + 1, k / dx)
	end
	LinearAdjoints.addentry(I, J, V, n, n, -2 * k / dx)
	return SparseArrays.sparse(I, J, V)
end
const k0 = float(pi)
n = 10
xs = range(0; stop=1, length=n + 2)[2:end - 1]
const hobs = randn(length(xs))
function objfunc(h, k, f)
	return sum((h - hobs) .^ 2) + (k - k0) ^ 2
end
function objfunc_h(h, k, f)
	return 2 * (h - hobs)
end
function objfunc_p(h, k, f)
	result = zeros(1 + length(f))
	result[1] = 2 * (k - k0)
	return result
end
@LinearAdjoints.adjoint h_and_grad laplacian rhs objfunc objfunc_h objfunc_p
k = k0
gwsink = fill(-2 * k0, n)
LinearAdjoints.testassembleb_p(rhs, rhs_p, [true, true], k, gwsink)
LinearAdjoints.testadjoint(h_and_grad, [true, true], k, gwsink)

#test jacobian code
function objfunc2(h, k, f)
	return (h[1] - hobs[1]) ^ 2 + (k[1] - k0[1]) ^ 2
end
function objfunc_h2(h, k, f)
	retval = zeros(length(h))
	retval[1] = 2 * (h[1] - hobs[1])
	return retval
end
function objfunc_p2(h, k, f)
	result = zeros(1 + length(f))
	result[1] = 2 * (k[1] - k0[1])
	return result
end
@LinearAdjoints.adjoint h_and_grad2 laplacian rhs objfunc2 objfunc_h2 objfunc_p2
@LinearAdjoints.adjoint h_and_jac laplacian rhs (objfunc, objfunc2) (objfunc_h, objfunc_h2) (objfunc_p, objfunc_p2)
@LinearAdjoints.solve h_grid laplacian rhs
xsolve = h_grid(k, gwsink)
x1, of1, gradient1 = h_and_grad(k, gwsink)
x2, of2, gradient2 = h_and_grad2(k, gwsink)
x, ofs, gradients = h_and_jac(k, gwsink)
@test xsolve == x
@test x1 == x2
@test x == x2
@test of1 == ofs[1]
@test of2 == ofs[2]
@test gradient1 == gradients[1]
@test gradient2 == gradients[2]
