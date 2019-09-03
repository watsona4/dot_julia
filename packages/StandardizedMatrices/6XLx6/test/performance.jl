module Performance

using StandardizedMatrices, BenchmarkTools, LinearAlgebra, StatsBase

n, p = 1000, 1000
x = randn(n, p)
x2 = zscore(x, 1)
z = StandardizedMatrix(x)
β = randn(p)
isapprox(x2 * β, z * β) ?
	info("Dense Matrix-Vector multiplication correct") :
	warn("Dense Matrix-Vector multiplication incorrect")
x = sprandn(n, p, .01)
x2 = zscore(x, 1)
z = StandardizedMatrix(x)
isapprox(x2 * β, z * β) ?
	info("Sparse Matrix-Vector multiplication correct") :
	warn("Sparse Matrix-Vector multiplication incorrect")


info("Dense A_mul_B! timing ratio")
b1 = @benchmark(
	A_mul_B!(storage, x, β),
	setup = (storage = zeros(n); x = StandardizedMatrix(randn(n, p)); β = randn(p))
)
b2 = @benchmark(
	A_mul_B!(storage, x, β),
	setup = (storage = zeros(n); x = randn(n, p); β = randn(p))
)
@show ratio(minimum(b1), minimum(b2))


info("Sparse A_mul_B! timing ratio")
b1 = @benchmark(
	A_mul_B!(storage, x, β),
	setup = (storage = zeros(n); x = StandardizedMatrix(sprandn(n, p, .05)); β = randn(p))
)
b2 = @benchmark(
	A_mul_B!(storage, x, β),
	setup = (storage = zeros(n); x = zscore(sprandn(n, p, .05), 1); β = randn(p))
)
@show ratio(minimum(b1), minimum(b2))


end
