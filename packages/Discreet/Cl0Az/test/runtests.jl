using Discreet
import StatsBase: FrequencyWeights, ProbabilityWeights
using Compat, Compat.Test
import Compat.sum

freqs_uniform = FrequencyWeights([1, 1, 1, 1, 1, 1])
probs_uniform = ProbabilityWeights([.5, .5])
sample = [:a, :b, :c, :d, :e, :f]

@testset "Entropy routines" begin
    ## Naive estimator
    @test log(6) ≈ entropy(freqs_uniform)
    @test 0 == entropy(FrequencyWeights([6]))
    @test log(6) ≈ estimate_entropy(sample)

    ## CS and shrinkage estimates, from library(entropy) in R
    @test 3.840549310406 ≈ entropy(FrequencyWeights([1,1,1,1,1,1]); method=:CS)
    @test 2.201137101279 ≈ entropy(FrequencyWeights([4,2,3,2,4,2,1,1]); method=:CS)
    @test 1.968382408728 ≈ entropy(FrequencyWeights([4,2,3,2,4,2,1,1]))
    @test 2.379602895309 ≈ entropy(FrequencyWeights([4,2,3,0,2,4,0,0,2,1,1]);
                                   method=:Shrink)

    ## Any other method
    @test_throws ArgumentError entropy(freqs_uniform; method=:NotImplemented)
    @test_throws ArgumentError estimate_entropy(sample; method=:NotImplemented)

    ## Joint entropy
    @test log(6) ≈ estimate_joint_entropy(sample, sample)
    @test 3.840549310406 ≈ estimate_joint_entropy(sample, sample; method=:CS)
end


@testset "Mutual information routines" begin
    labels_a = [1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3]
    labels_b = [1, 1, 1, 1, 2, 1, 2, 2, 2, 2, 3, 1, 3, 3, 3, 2, 2]

    mi = mutual_information(labels_a, labels_b)
    @test 0.41022 ≈ mi atol=1e-5

    e_a = estimate_entropy(labels_a)
    e_b = estimate_entropy(labels_b)
    mi_normalized = mutual_information(labels_a, labels_b; normalize=true)
    @test mi / min(e_a, e_b) ≈ mi_normalized

    data = hcat(sample, sample, sample)
    @test log(6) * ones(3, 3) ≈ mutual_information(data)
end


@testset "Contingency tables" begin
    d = rand(10, 10)
    table = d / sum(d)
    mi_1 = mutual_information_contingency(table)
    @compat e_a, e_b =  entropy(sum(table, dims=1)), entropy(sum(table, dims=2))
    mi_2 = e_a + e_b - entropy(table[:])
    @test mi_1 ≈ mi_2

    ## Normalized MI
    mi_norm = mutual_information_contingency(table; normalize=true)
    @test mi_norm ≈ mi_1 / min(e_a, e_b)

    ## Table with no association
    @test 0 ≈ mutual_information_contingency(ones(20, 5) / 100) atol=1e-10
end
