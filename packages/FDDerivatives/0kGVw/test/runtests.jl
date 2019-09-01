import FDDerivatives
import Random
import Test

function basictest()
	function f(x::Array{Float64, 1})
		return [x[1] + .5 * x[2], x[1] ^ 2, sin(x[2]), cos(x[1])]
	end
	function jacobianf(x::Array{Float64, 1})
		return [1. .5; 2 * x[1] 0.; 0. cos(x[2]); -sin(x[1]) 0.]
	end
	testjacobianf = FDDerivatives.makejacobian(f)
	x = [1., 2.]
	@Test.test jacobianf(x) ≈ testjacobianf(x) atol=1e-4
	for i = 1:10000
		x = 10 * randn(2)
		@Test.test jacobianf(x) ≈ testjacobianf(x) atol=1e-4
	end
end

Random.seed!(0)
basictest()
