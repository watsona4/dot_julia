c = ingleton(4,1,2,3,4)
cut = nonnegative(4, 1234)
n = 4
h = polymatroidcone(Float64, 4)
newcut = :AddImmediately

using CutPruners
using StructDualDynProg

@testset "Ingleton score" begin
    @testset "n = $n, m = $m, nits=$nits, objval=$objval" for (n, m, nnodes, nits, objval, ncuts, ncuts_nonred) in ((4, 1, 1, 1, -1/4,  0, 0), # Shannon cone without any adhesivity
                                                                                                                    (5, 1, 4, 1, -1/4,  0, 0), # Adhesivity adding up to n=5 but paths of length m=1 so they are not encountered
                                                                                                                    (5, 2, 4, 2, -1/6, 24, 4)) # n=5, m=2 so they are encountered and we have 6 new cuts that improves the Ingleton bound to -1/6
        (sp, allnodes) = StructDualDynProg.SOI.stochasticprogram(m, c, h, lp_solver, n, cut, newcut,
                                                                 AvgCutPruningAlgo.([-1,-1,-1,-1,-1,-1,-1]))
        algo = StructDualDynProg.SDDP.Algorithm(K = -1)
        info = StructDualDynProg.SOI.optimize!(sp, algo, StructDualDynProg.SOI.IterLimit(nits))
        @test length(allnodes) == nnodes
        res = StructDualDynProg.SOI.last_result(info)
        @test res.status == :Optimal
        @test res.lowerbound ≈ objval
        @test res.upperbound ≈ objval
        @test CutPruners.ncuts(sp.data[1].nlds.FCpruner) == ncuts
        CutPruners.exactpruning!(sp.data[1].nlds.FCpruner, lp_solver)
        @test CutPruners.ncuts(sp.data[1].nlds.FCpruner) == ncuts_nonred
    end
end
