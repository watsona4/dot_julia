module FDDerivatives

import Distributed
import LinearAlgebra

"Create Jacobian function"
function makejacobian(f::Function, h::Float64=sqrt(eps(Float64)))
	function jacobian(x::Vector)
		xphs = Array{Array{Float64, 1}}(undef, length(x) + 1)
		for i = 1:length(x)
			xphs[i] = copy(x)
			xphs[i][i] += h
		end
		xphs[end] = copy(x)
		ys = Distributed.pmap(f, xphs)
		J = Array{eltype(ys[1])}(undef, length(ys[1]), length(x))
		for i = 1:length(x)
			J[:, i] = ys[i] - ys[end]
		end
		LinearAlgebra.lmul!(1 / h, J)
		return J
	end
end

"Create Gradient function"
function makegradient(f::Function, h::Float64=sqrt(eps(Float64)))
	function gradient(x::Vector)
		xphs = Array{Array{Float64, 1}}(undef, length(x) + 1)
		for i = 1:length(x)
			xphs[i] = copy(x)
			xphs[i][i] += h
		end
		xphs[end] = copy(x)
		ys = Distributed.pmap(f, xphs)
		grad = Array{eltype(ys)}(undef, length(x))
		for i = 1:length(x)
			grad[i] = ys[i] - ys[end]
		end
		LinearAlgebra.lmul!(1 / h, grad)
		return grad
	end
end

end
