import GeostatInversion
import Test
import Random
import Statistics

@stderrcapture function testNd(N)
	Ns = map(x->round(Int, 25 * x), 1 .+ rand(N))
	k0 = randn()
	dk = rand()
	beta = -2 - rand()
	k = GeostatInversion.FFTRF.powerlaw_structuredgrid(Ns, k0, dk, beta)
	@Test.test Statistics.mean(k) ≈ k0
	@Test.test Statistics.std(k) ≈ dk
	@Test.test collect(size(k)) == Ns
end

@stderrcapture function testunstructured(N)
	points = randn(N, 100)
	Ns = map(x->round(Int, 25 * x), 1 .+ rand(N))
	k0 = randn()
	dk = rand()
	beta = -2 - rand()
	k = GeostatInversion.FFTRF.powerlaw_unstructuredgrid(points, Ns, k0, dk, beta)
	@Test.test length(k) == size(points, 2)
end

Random.seed!(2017)
@Test.testset "FTRF" begin
	for i = 1:10
		testunstructured(2)
		testunstructured(3)
		testNd(2)
		testNd(3)
	end
end

