module Tests
using StandardizedMatrices, StatsBase, Statistics, LinearAlgebra, Test


n, p, k = 100, 5, 7
x = randn(n, p)
x2 = zscore(x, 1)
z = StandardizedMatrix(x)
b = randn(p)
b2 = randn(n)
b3 = randn(p, k)
b4 = randn(n, k)

@testset "Multiplication with Vector" begin
	@test isapprox(z * b, x2 * b)
	storage = zeros(n)
	mul!(storage, z, b)
	@test isapprox(storage, x2 * b)
	storage = zeros(p)
	mul!(storage, z', b2)
	@test isapprox(storage, x2' * b2)
end

@testset "Multiplication with Matrix" begin
	@test isapprox(z * b3, x2 * b3)
	storage = zeros(n, k)
	mul!(storage, z, b3)
	@test isapprox(storage, x2 * b3)
	storage = zeros(p, k)
	mul!(storage, z', b4)
	@test isapprox(storage, x2' * b4)
end

@testset "Indexing" begin
	for i in eachindex(z)
		@test z[i] == x2[i]
	end
	for j in 1:size(z, 2), i in 1:size(z, 1)
		@test z[i, j] == x2[i, j]
	end
end


end #module
