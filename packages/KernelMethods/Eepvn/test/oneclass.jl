using Test

include("loaddata.jl")

@testset "encode by farthest points" begin
    using KernelMethods.KMap
    using SimilaritySearch
    using KernelMethods.Scores
    using StatsBase: mean

    X, ylabels = loadiris()
    dist = lp_distance(3.3)
    L = Float64[]
    for label in ["Iris-setosa", "Iris-versicolor", "Iris-virginica"]
        y = ylabels .== label
        A = X[y]
        B = X[.~y]
        occ = fit(OneClassClassifier, dist, A, 21)
        ypred = [predict(occ, dist, x).similarity > 0 for x in X]
        push!(L, mean(ypred .== y))
        println(stderr, "==> $label: $(L[end])")
    end

    macrorecall = mean(L)
    println(stderr, "===> macro-recall: $macrorecall")
    @test macrorecall > 0.9
end