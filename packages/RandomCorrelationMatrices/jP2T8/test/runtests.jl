import LinearAlgebra: cholesky, diag, Diagonal, Hermitian
import Printf: @printf
import Random
import Statistics: mean, median, std
using Test
import RandomCorrelationMatrices

# This is not a numerical test. The code just generates some examples.
# However, if it fails to run, thats a good sign something is wrong.
Random.seed!(12345)
println("Random correlation matrix")
n = 4
for η in [2, 8, 32, 128]
    r = RandomCorrelationMatrices.randcormatrix(n, η)
    @show η
    for i in 1:n
        for j in 1:n
            @printf("%5.2f ", r[i,j])
        end
        println()
    end

    ranges = Float64[]
    for s in 1:1000
        r = RandomCorrelationMatrices.randcormatrix(n, η)
        r0 = r - Matrix(Diagonal((diag(r))))
        push!(ranges, maximum(vec(r0)) - minimum(vec(r0)))
    end
    @show mean(ranges)
    @show median(ranges)
end


@testset "Random covariance matrix" begin
    Random.seed!(12345)
    σ = [100, 200, 300, 400, 500]
    Σ = RandomCorrelationMatrices.randcovmatrix(5, 10, σ)
    L = cholesky(Hermitian(Σ)).L
    samples = 100_000
    results = zeros(5, samples)
    for i in 1:samples
        results[:,i] = L*randn(5)
    end
    means = mean(results, dims=2)
    @test all(abs.(means) .<= 5)
    stddevs = std(results, dims=2)
    @test all(abs.(stddevs - σ) .<= 5)
    @show σ
    @show round.(stddevs, digits=1)
end