import GeostatInversion
import RobustPmap
import Test
import SparseArrays
import LinearAlgebra
import Random
using Distributed
using SparseArrays

@stderrcapture function pcgalowranksize(numetas=10, numobs=20)
	etas = [rand(numobs) for i = 1 : numetas]
	HX = rand(10)
	R = spzeros(10, 10)
	A = GeostatInversion.PCGALowRankMatrix(etas, HX, R)
	@Test.test size(A) == (size(A, 1), size(A, 2))
end

@stderrcapture function simplepcgalowranktest(numetas=10, numobs=20)
	#[(HQH + R) HX; transpose(HX) zeros(p, p)]
	noiselevels = [1e16, 0.]#none, nuge
	etagenerators = [zeros, randn]
	HXgenerators = [zeros, randn]
	etas = Array{Array{Float64, 1}}(undef, numetas)
	for noiselevel in noiselevels
		for etagenerator in etagenerators
			for HXgenerator in HXgenerators
				HQH = zeros(numobs, numobs)
				for i = 1:numetas
					etas[i] = etagenerator(numobs)
					LinearAlgebra.BLAS.ger!(1., etas[i], etas[i], HQH)
				end
				HX = HXgenerator(numobs)
				R = noiselevel * SparseArrays.SparseMatrixCSC(LinearAlgebra.I, numobs, numobs)
				bigA = [(HQH + R) HX; transpose(HX) zeros(1, 1)]
				lrbigA = GeostatInversion.PCGALowRankMatrix(etas, HX, R)
				for i = 1:numobs + 1
					x = zeros(numobs + 1)
					x[i] = 1.
					@Test.test isapprox(bigA * x, lrbigA * x)
				end
			end
		end
	end
end

@stderrcapture function simplelowrankcovtest()
	samples = Array{Float64, 1}[[-.5, 0., .5], [1., -1., 0.], [-.5, 1., -.5]]
	lrcm = GeostatInversion.LowRankCovMatrix(samples)
	fullcm = LinearAlgebra.Matrix{Float64}(LinearAlgebra.I, 3, 3) * lrcm
	@Test.test isapprox(fullcm, lrcm * LinearAlgebra.Matrix{Float64}(LinearAlgebra.I, 3, 3))
	@Test.test isapprox(sum(map(x->x * x', samples)) / (length(samples) - 1), fullcm)
	@Test.test isapprox(sum(map(x->x * x', samples)) / (length(samples) - 1), fullcm)
	for i = 1:100
		x = randn(3, 3)
		@Test.test isapprox(fullcm * x, lrcm * x)
		@Test.test isapprox(fullcm' * x, lrcm' * x)
	end
end

@stderrcapture function lowrankcovconsistencytest()
	N = 10000
	M = 100
	sqrtcovmatrix = randn(M, M)
	covmatrix = sqrtcovmatrix * sqrtcovmatrix'
	samples = Array{Array{Float64, 1}}(undef, N)
	onesamples = Array{Float64}(undef, N)
	twosamples = Array{Float64}(undef, N)
	for i = 1:N
		samples[i] = sqrtcovmatrix * randn(M)
		onesamples[i] = samples[i][1]
		twosamples[i] = samples[i][2]
	end
	lrcm = GeostatInversion.LowRankCovMatrix(samples)
	lrcmfull = lrcm * LinearAlgebra.Matrix{Float64}(LinearAlgebra.I, M, M)
	@Test.test isapprox(LinearAlgebra.norm(lrcmfull - covmatrix, 2), 0.; atol=M ^ 2 / sqrt(N))
	for i = 1:100
		x = randn(M)
		@Test.test isapprox(lrcm * x, lrcmfull * x)
	end
end

@stderrcapture function lowrankcovgetxistest()
	numfields = 100
	numxis = 30
	p = 20
	samplefield() = GeostatInversion.FFTRF.powerlaw_structuredgrid([25, 25], 2., 3.14, -3.5)[1:end]
	lrcmxis, fields = GeostatInversion.getxis(Val{:iwantfields}, samplefield, numfields, numxis, p, 3, 0)
	lrcm = GeostatInversion.LowRankCovMatrix(fields)
	fullcm = LinearAlgebra.Matrix{Float64}(LinearAlgebra.I, size(lrcm, 1), size(lrcm, 1)) * lrcm
	fullxis = GeostatInversion.getxis(fullcm, numxis, p, 3, 0)
	for i = 1:length(fullxis)
		#=
		Apparently due to minor discrepancies (rounding error), the LU decomposition is not
		consistently reproducible. As a consequence, the randsvd part of the getxis can
		return + or - the singular vectors. We check that it is close to + or - the xis
		we get from the full matrix.
		=#
		#This test is also tricky because the randsvd's in the two getxis calls need to be generating the same random numbers
		@Test.test isapprox(0., min(LinearAlgebra.norm(fullxis[i] - lrcmxis[i]), LinearAlgebra.norm(fullxis[i] + lrcmxis[i])), atol=1e-6)
	end
end

@stderrcapture function setupsimpletest(M, N, mu)
	x = randn(N)
	Q0 = randn(M, N)
	Q = Q0' * Q0
	sqrtQ = Q^0.5
	truep = real(sqrtQ * randn(N)) .+ mu
	function forward(p::Vector)
		return p .* x
	end
	truey = forward(truep)
	xis = GeostatInversion.getxis(Q, M, round(Int, 0.1 * M))
	X = fill(mu, N)
	noiselevel = 0.0001
	R = noiselevel ^ 2 * SparseArrays.SparseMatrixCSC(LinearAlgebra.I, N, N)
	yobs = truey + noiselevel * randn(N)
	p0 = fill(mu, N)
	return forward, p0, X, xis, R, yobs, truep
end

@stderrcapture function simpletestpcga(M::Int, N::Int, mu::Float64=0.)
	forward, p0, X, xis, R, yobs, truep = setupsimpletest(M, N, mu)
	popt = GeostatInversion.pcgadirect(forward, p0, X, xis, R, yobs)
	@Test.test isapprox(LinearAlgebra.norm(popt - truep) / LinearAlgebra.norm(truep), 0., atol=2e-2)
	if M < N / 6
		popt = GeostatInversion.pcgalsqr(forward, p0, X, xis, R, yobs)
		@Test.test isapprox(LinearAlgebra.norm(popt - truep) / LinearAlgebra.norm(truep), 0., atol=2e-2)
	end
end

@stderrcapture function simpletestrga(M::Int, N::Int, Nreduced::Int, mu::Float64=0.)
	forward, p0, X, xis, R, yobs, truep = setupsimpletest(M, N, mu)
	S = randn(Nreduced, N) * (1 / sqrt(N))
	popt = GeostatInversion.rga(forward, p0, X, xis, R, yobs, S)
	@Test.test isapprox(LinearAlgebra.norm(popt - truep) / LinearAlgebra.norm(truep), 0., atol=2e-2)
end

#=
function simpletestpcgalm(M, N, mu=0.)
	forward, p0, X, xis, R, yobs, truep = setupsimpletest(M, N, mu)
	popt = GeostatInversion.pcgalm(forward, p0, X, xis, diag(R), yobs)
	@Test.test_approx_eq_eps LinearAlgebra.norm(popt - truep) / LinearAlgebra.norm(truep) 0. 2e-2
end
=#

@Test.testset "RPSGA" begin
	@everywhere Random.seed!(2017)
	pcgalowranksize()
	simplepcgalowranktest()
	simplelowrankcovtest()
	lowrankcovconsistencytest()
	lowrankcovgetxistest()
	simpletestrga(2 ^ 3, 2 ^ 10, 2 ^ 9)
	simpletestrga(2 ^ 3, 2 ^ 11, 2 ^ 9)
	simpletestrga(2 ^ 3, 2 ^ 10, 2 ^ 9, 10.)
	simpletestrga(2 ^ 3, 2 ^ 11, 2 ^ 9, 10.)
	maxlog2N = 8
	minlog2N = 2
	for log2N = minlog2N:maxlog2N
		for log2M = 0:log2N - 1
			N = 2 ^ log2N
			M = 2 ^ log2M
			simpletestpcga(M, N)
			simpletestpcga(M, N, 10.)
			#simpletestpcgalm(M, N)
			#simpletestpcgalm(M, N, 10.)
		end
	end
end
:passed
