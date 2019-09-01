@testset "Decay cut pruning" begin
    algo = DecayCutPruningAlgo(2)
    pruner = CutPruner{2, Int}(algo, :≤)
    @test 1:1 == addcuts!(pruner, [1 0], [2], [true])
    addposition!(pruner, [1, 0])
    @test [1, 2] == addcuts!(pruner, [1 0; 0 1], [1, 2], [true, true])
    @test pruner.A == [1 0; 0 1]
    @test pruner.b == [1, 2]
    @test pruner.ids == [3, 2]
    addusage!(pruner, [0, 1])
    @test [1, 0] == addcuts!(pruner, [0 1; 0 1], [1, 3], [true, false])
    @test pruner.A == [0 1; 0 1]
    @test pruner.b == [1, 2]
    @test pruner.ids == [4, 2]
end
