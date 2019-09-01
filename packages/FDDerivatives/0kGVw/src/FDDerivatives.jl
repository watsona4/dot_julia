module FDDerivatives

import Distributed
import LinearAlgebra

function makejacobian(f, h=sqrt(eps(Float64)))
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
		LinearAlgebra.rmul!(J, 1 / h)
		return J
	end
end

function makegradient(f, h=sqrt(eps(Float64)))
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
		LinearAlgebra.rmul!(grad, 1 / h)
		return grad
	end
end

end
