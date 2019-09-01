using Test 
using EMIRT
using EMIRT.AffinityMaps

@testset "test affinitymap" begin 
    aff = rand(Float32, 128,128,16,3)

    println("transform affinitymap to edge list...")
    @time aff2edgelist(aff)

    println("segment affinity map using connectivity analysis ...")
    @time aff2seg(aff)

    println("transform to uniform distribution ...")
    @time aff2uniform(aff)

    println("exchange x and z axis of affinity map...")
    @time exchangeaffxz!(aff)
end # end of test set
