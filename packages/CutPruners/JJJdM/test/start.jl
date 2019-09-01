@testset "Initialization" begin
    for algo in [AvgCutPruningAlgo(1), DecayCutPruningAlgo(1), DeMatosPruningAlgo(3)]
        @test_throws ArgumentError CutPruner{2, Int}(algo, :Mix)
        for sense in [:Min, :Max, :≤, :≥]
            pruner = CutPruner{2, Int}(algo, sense)
            @test isempty(pruner)
            @test ncuts(pruner) == 0
            @test CutPruners.isfun(pruner) == (sense in [:Min, :Max])
            @test CutPruners.islb(pruner) == (sense in [:Max, :≥])
            @test CutPruners.getsense(pruner) == sense
        end
    end
end

@testset "Keeponly" begin
    for algo in [AvgCutPruningAlgo(3), DecayCutPruningAlgo(3), DeMatosPruningAlgo(3)]
        pruner = CutPruner{2, Int}(algo, :≤)
        @test isempty(pruner)
        addcuts!(pruner, [1 2; 3 4; 5 6], [7, 8, 9], BitArray(undef, 3))
        @test !isempty(pruner)
        keeponlycuts!(pruner, [3, 1])
        @test pruner.A == [5 6; 1 2]
        @test pruner.b == [9, 7]
        @test pruner.ids == [3, 1]
        removecuts!(pruner, [2])
        @test pruner.A == [5 6]
        @test pruner.b == [9]
        @test pruner.ids == [3]
    end
end

@testset "Check redundancy" begin
    # check redundant
    TOL = 1e-6
    A = rand(10, 2)
    b = rand(10)
    ck = CutPruners.isinside(A, b, A[1,:], true, TOL)
    @test ck[1]

    Anew = A[9:10, :]
    bnew = b[9:10]
    red = CutPruners.checkredundancy(A, b, Anew, bnew, true, true, TOL)
    @test red == [1, 2]
    A = rand(10, 2)
    ck = CutPruners.isinside(A, b, A[1,:], true, TOL)
    @test ck[1]

    # check non redundant
    b = rand(10)
    Anew = rand(2, 2)
    ck = CutPruners.isinside(A, b, Anew[1, :], true, TOL)
    @test ~ck[1]
    bnew = rand(2)
    red = CutPruners.checkredundancy(A, b, Anew, bnew, true, true, TOL)
    @test red == []
end
