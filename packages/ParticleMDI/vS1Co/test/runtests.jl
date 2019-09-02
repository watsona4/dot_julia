using Distributions
using ParticleMDI

@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end


## Test data types
# Gaussian
n = 1000
test_data = rand(Normal(0, 1), n, 1)
test_cluster = ParticleMDI.GaussianCluster(test_data)
# Basic check it's been initialised
@test test_cluster.n == 0
# Check the logprob
# ParticleMDI.calc_logprob(test_data[1, :], test_cluster)
for obs in test_data
    ParticleMDI.cluster_add!(test_cluster, [obs], [true])
end

@test test_cluster.n == n
@test isapprox(test_cluster.Σ[1], sum(test_data))
@test isapprox(test_cluster.μ[1], test_cluster.Σ[1] / (n + 0.001))
xbar = test_cluster.Σ[1] / n
s2 = sum((test_data .- xbar) .^ 2)
beta = 0.5 + 0.5 * (s2 + (0.001 * n * xbar ^ 2) / (n + 0.001))
@test isapprox(test_cluster.β[1], beta)
@test isapprox(test_cluster.λ[1], ((0.5 + n * 0.5) * (n + 0.001)) / (test_cluster.β[1] * (n + 1.001)))

xcentred = (test_data[end, :][1] - test_cluster.μ[1]) * sqrt(test_cluster.λ[1])
truelogprob = logpdf(TDist(test_cluster.n + 1), xcentred) + 0.5 * log(test_cluster.λ[1])
estlogprob = ParticleMDI.calc_logprob(test_data[end, :], test_cluster, [true])
@test isapprox(truelogprob, estlogprob)

# Categorical
test_data = rand(1:10, 1000, 1)
test_cluster = ParticleMDI.CategoricalCluster(test_data)
@test test_cluster.n == 0

for obs in test_data
    ParticleMDI.cluster_add!(test_cluster, [obs], [true])
end

@test test_cluster.n == 1000
test_cluster.counts
for x in unique(test_data)
    @test sum(test_data .== x) == test_cluster.counts[x, 1]
end

@test isapprox(ParticleMDI.calc_logprob([1], test_cluster, [true]),
      log((sum(test_data .== 1) + 0.5) / (1005)))


# Test normalising constant calculation
for N = 2:20
    for K = 1:5
        c_combn = Matrix{Int64}(undef, N ^ K, K)
        for k in 1:K
            c_combn[:, K - k + 1] = div.(0:(N ^ K - 1), N ^ (K - k)) .% N .+ 1
        end
        γc = rand(Gamma(1.0 / N, 1), N, K)
        Γ = Matrix{Float64}(undef, N ^ K, K)
        for i in 1:(N ^ K)
            for k in 1:K
                Γ[i, k] = γc[c_combn[i], k]
            end
        end
        if K > 1
            Φ = rand(Gamma(1, 5), binomial(K, 2), 1)
        else
            Φ = zeros(1)
        end
        phi_index = zeros(Int64, K- 1, K)
        num = 1
        for i in 1:(K - 1)
            for j in (i + 1):K
                phi_index[i, j] = num
                num += 1
            end
        end
        Z = 0.0
        for i in 1:(N ^K)
            tmp = prod(Γ[i, :])
            if K > 1
                for k1 in 1:(K - 1)
                    for k2 in (k1 + 1):K
                        tmp *=  (1 + (Φ[phi_index[k1, k2]] * (c_combn[i, k1] == c_combn[i, k2])))
                    end
                end
            end
            Z += tmp
        end
        Φ_index = K > 1 ? Matrix{Bool}(undef, N ^ K, Int64(K * (K - 1) / 2)) : fill(1, (N, 1))
        if K > 1
            i = 1
            for k1 in 1:(K - 1)
                for k2 in (k1 + 1):K
                    Φ_index[:, i] = (c_combn[:, k1] .== c_combn[:, k2])
                    i += 1
                end
            end
        end
        @test isapprox(Z, ParticleMDI.update_Z(Φ, Φ_index, log.(Γ)))
    end
end


# Test cluster alignment
# All datasets strongly agree
K = 5
N = 10
s = rand(1:N, 10000, K)
Φ = [10 for k in 1:binomial(K, 2)]
γ = rand(Gamma(1.0 / N, 1), N, K)
# Perfect agreement up to label permutation
for k in 2:K
    shuf = Distributions.shuffle(1:N)
    s[:, k] .= shuf[s[:, 1]]
    γ[:, k] = γ[indexin(1:N, shuf), 1]
end
# No guarantee that agreement occurs at first attempt
# Run over and over and check that if all the cluster values align
# So do all the gammas
for i = 1:10
    ParticleMDI.align_labels!(s, Φ, γ, N, K)
    @test all(s[:, 2:K] .== s[:, 1]) == all(γ[:, 2:K] .== γ[:, 1])
end
ParticleMDI.align_labels!(s, Φ, γ, N, 0)

@test all(s[:, 2:K] .== s[:, 1])
@test all(γ[:, 2:K] .== γ[:, 1])
