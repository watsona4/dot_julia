@testset "Avg cut pruning" begin
    algo = AvgCutPruningAlgo(2)
    pruner = CutPruner{2, Int}(algo, :≤)
    # check redundancy between new and old cuts
    pruner.excheck = true

    addposition!(pruner, [1, 0])
    @test 1:1 == addcuts!(pruner, [1 0], [1], [true])
    @test 2:2 == addcuts!(pruner, [0 1], [1], [false])
    addusage!(pruner, [1, 0])
    @test [2, 0, 0] == addcuts!(pruner, [1 1; -1 -1; 0 1], [1, 1, 2], [true, false, true])
    @test pruner.A == [1 0; 1 1]
    @test pruner.b == [1, 1]
    @test pruner.ids == [1, 3]
    @test [0, 0] == addcuts!(pruner, [1 0; 1 1], [1, 1], [true, true])
    @test pruner.A == [1 0; 1 1]
    @test pruner.b == [1, 1]
    @test pruner.ids == [1, 3]
    addusage!(pruner, [1, 0])
    @test [2, 0] == addcuts!(pruner, [2 0; 0 2], [0, 0], [false, false])
end
