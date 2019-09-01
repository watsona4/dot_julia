@testset "TSP  $G" begin
    @testset "random instances" begin
        n = 10
        g = CompleteGraph(n, G)
        for seed=7:20
            # println("##### Seed $seed #############")
            Random.seed!(seed)
            w = EdgeMap(g, e->rand())
            status, W, tour = solve_tsp(g, w, verb=false)
            @test status == :Optimal
            @test 0 < W < n
            @test length(tour) == n
            @test tour[1] == 1
            @test unique(tour) == tour

            status, W2, tour2 = solve_tsp(g, w, cutoff = 0.9, verb=false)
            @test status == :Optimal
            @test 0 < W2 < n
            @test length(tour2) == n
            @test tour2[1] == 1
            @test unique(tour2) == tour2
            # @test tour2 ==  tour
        end
    end
end
