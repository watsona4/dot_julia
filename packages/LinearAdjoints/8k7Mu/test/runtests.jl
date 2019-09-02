using Test
import LinearAdjoints
import Calculus

include("testtransforms.jl")
include("diagonaltest.jl")
include("laplaciantest.jl")
include("rhstest.jl")
include("fulladjointtest.jl")

#=
q2 = quote
	@LinearAdjoints.assemblesparsematrix (a, c) x function f(a, b, c)
		@assert length(a) == length(b) - 1
		@assert length(a) == length(c)
		I = Int[]
		J = Int[]
		V = Float64[]
		for i = 1:length(a)
			LinearAdjoints.addentry(I, J, V, i + 1, i, a[i] + b[i] ^ 2)
		end
		for i = 1:length(b)
			LinearAdjoints.addentry(I, J, V, i, i, b[i])
		end
		for i = 1:length(c)
			LinearAdjoints.addentry(I, J, V, i, i + 1, log(c[end - i + 1]))
		end
		return sparse(I, J, V)
	end
end
#@show macroexpand(q2)
#eval(q2)
q3 = quote
	@LinearAdjoints.assemblesparsematrix (a, c) x function f(a, b, c)
		LinearAdjoints.addentry(I, J, V, 1, 2, a[1] ^ 3 + exp(c[end - 1 + 1, j]))
		LinearAdjoints.addentry(I, J, V, 2, 1, a[2] ^ 3 + exp(c[end - 2 + 1, j]))
		#LinearAdjoints.addentry(I, J, V, 1, 2, a ^ 3 + exp(c[1 - 1 + 1]))
	end
end
q = :(b[1] = a[1] ^ 2 + sqrt(c[end - 1 + 1]))
q4 = quote
	@LinearAdjoints.assemblevector (a, c) b function f(a, c)
		b = Array{Float64}(1)
		$q
		b[end] = 1
		return b
	end
end
macroexpand(q3)
#eval(q3)
#eval(q2)
#LinearAdjoints.adjointsparsematrix(:(LinearAdjoints.addentry(I, J, V, 1, 2, a[1])))
=#
