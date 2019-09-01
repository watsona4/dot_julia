import GeostatInversion
import LinearAlgebra
import Test

@stderrcapture function makeA(n, m)
	range = randn(n, m)
	other = randn(m, n)
	return range * other
end

@stderrcapture function test_rangefinder(n, m)
	A = makeA(n, m)
	Q = GeostatInversion.RandMatFact.rangefinder(A)
	@Test.test isapprox(m, size(Q, 2), atol=1)
	@Test.test isapprox(LinearAlgebra.norm(A - Q * Q' * A), 0., atol=1e-8)
	Q = GeostatInversion.RandMatFact.rangefinder(A, m, 2)
	@Test.test isapprox(m, size(Q, 2), atol=1)
	@Test.test isapprox(LinearAlgebra.norm(A - Q * Q' * A), 0., atol=1e-8)
end

@stderrcapture function test_eig_nystrom()
	A = Float64[2 -1 0; -1 2 -1; 0 -1 2]
	Q = GeostatInversion.RandMatFact.rangefinder(A)
	U, Sigmavec = GeostatInversion.RandMatFact.eig_nystrom(A, Q)
	Sigma = LinearAlgebra.Diagonal(Sigmavec)
	Lambda = Sigma * Sigma
	eigvals, eigvecs = LinearAlgebra.eigen(A)
	@Test.test isapprox(LinearAlgebra.norm(sort(eigvals, rev=true) - LinearAlgebra.diag(Lambda)), 0., atol=1e-8)
end

@Test.testset "RMF" begin
	test_rangefinder(10, 2)
	test_rangefinder(10, 5)
	test_rangefinder(100, 5)
	test_rangefinder(100, 10)
	test_rangefinder(100, 25)
	test_eig_nystrom()
	#=
	#some tests for scaling performance
	@time A = makeA(1000, 20)
	@time Q = RandMatFact.rangefinder(A)
	nothing
	=#
end
