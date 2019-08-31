using ClusteringGA
using Clustering
using Test

tests = ["ClusteringGA"]

println("Runing tests:")
for t in tests
    fp = "$(t).jl"
    println("* $fp ...")
    include(fp)
end
