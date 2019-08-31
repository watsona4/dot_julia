function k(α,β,γ)

			x̂ = cartesian(α)
			ξ = cartesian(β)[1]
			η = cartesian(γ)[1]

			ŷ = [ξ*(1-η), η]

			#jacobian of y--->ŷ = (1-y[2])

			chartI = simplex(p1,x̂,p0)
			chartII = simplex(p2,x̂,p1)
			chartIII = simplex(p0,x̂,p2)

			n1 = neighborhood(chartI, ŷ)
			n2 = neighborhood(chartII, ŷ)
			n3 = neighborhood(chartIII, ŷ)


			yI = cartesian(n1)
			yII = cartesian(n2)
			yIII = cartesian(n3)

			return(Kernel(x̂,yI)*jacobian(n1)*(1-η) +
					Kernel(x̂,yII)*jacobian(n2)*(1-η) +
					Kernel(x̂,yIII)*jacobian(n3)*(1-η))
end

function verifintegral1(sourcechart::CompScienceMeshes.Simplex{3,2,1,3,Float64},
	 testchart::CompScienceMeshes.Simplex{3,2,1,3,Float64}, integrand, accuracy::Int64)

	global Kernel, p0, p1, p2

	Kernel = integrand

	p0 = Sourcechart.vertices[1]
	p1 = Sourcechart.vertices[2]
	p2 = Sourcechart.vertices[3]

	qps1 = quadpoints(Sourcechart, accuracy)

	path = simplex(point(0), point(1))
	qps2 = quadpoints(path, accuracy)

	result = sum(w*w2*w1*k(α,β,γ) for (β,w1) in qps2, (γ,w2) in qps2, (α,w) in qps1)

	return (result)

end



function verifintegral2(sourcechart::CompScienceMeshes.Simplex{3,2,1,3,Float64},
	 testchart::CompScienceMeshes.Simplex{3,2,1,3,Float64}, integrand, accuracy::Int64)

	qps1 = quadpoints(sourcechart, accuracy)
	qps2 = quadpoints(testchart, accuracy)

	result = sum(w2*w1*integrand(cartesian(x),cartesian(y))
				for (x,w2) in qps2, (y,w1) in qps1)

	return (result)

end
