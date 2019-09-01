using CutPruners
using Compat, Compat.Test

include("solvers.jl")

isempty(lp_solvers) && warn("Exact Pruning tests not run!")
@testset "Exact Pruning with $solver" for solver in lp_solvers
    for algo in [AvgCutPruningAlgo(20), DecayCutPruningAlgo(20), DeMatosPruningAlgo(20)]
        @testset "Exact pruning" begin
            pruner = CutPruner{2, Int}(algo, :Max)

            # test pruning with one cut
            addcuts!(pruner, [1 0], [0], [true])
            exactpruning!(pruner, solver)
            @test pruner.b == [0]

            # add 10 cuts in a row
            for i in 1:10
                addcuts!(pruner, [1 0], [i], [true])
            end

            exactpruning!(pruner, solver)
            # normally the exact pruning saves only the last cuts
            @test pruner.b == [10]
            # ... and add another set of cuts ...
            for i in 1:10
                addcuts!(pruner, [2 0], [i+10], [true])
            end

            exactpruning!(pruner, solver)
            # perform the same test again
            @test pruner.b == [10, 20]
        end
    end
    for algo in [AvgCutPruningAlgo(20), DecayCutPruningAlgo(20), DeMatosPruningAlgo(20)]
        @testset "Exact pruning" begin
            pruner = CutPruner{2, Int}(algo, :Min)
            # add 10 cuts in a row
            for i in 1:10
                addcuts!(pruner, [1 0], [i], [true])
            end

            exactpruning!(pruner, solver)
            # normally the exact pruning saves only the last cuts
            @test pruner.b == [1]
            # ... and add another set of cuts ...
            for i in 1:10
                addcuts!(pruner, [2 0], [i+10], [true])
            end

            exactpruning!(pruner, solver)
            # perform the same test again
            @test pruner.b == [1, 11]
        end
    end
end
