@testset "bmatching  $G" begin

for seed=1:20
    Random.seed!(seed)
    n = 30
    g = random_regular_graph(n, 10)
    w = EdgeMap(g, e->rand())
    for b =2:4
        status, W, mates = minimum_weight_perfect_bmatching(g, b, w)
        @test status == :Optimal
        @test  0 < W < b*n/2
        @test length.(mates) == fill(b, n)
        mts = vcat(mates...)
        for i=1:nv(g)
            count(x->x==i, mts) == b
        end

        status2, W2, mates2 = minimum_weight_perfect_bmatching(g, b, w, cutoff=0.9)
        @test status2 == :Optimal
        @test  0 < W2 < n
        @test length.(mates2) == fill(b, nv(g))
        mts = vcat(mates2...)
        for i=1:nv(g)
            count(x->x==i, mts) == b
        end
        #@test mates == mates2
    end
end

end # testset
