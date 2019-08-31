using Compat
using Compat.Test
using SemidefiniteModels
import MathProgBase
const MPB = MathProgBase.SolverInterface

function sdtest(solver::MathProgBase.AbstractMathProgSolver; duals=false, tol=1e-6)
    @testset "Testing SDModel with $solver" begin
        m = MPB.ConicModel(solver)
        MPB.loadproblem!(m, "prob.dat-s")
        MPB.optimize!(m)
        @test MPB.status(m) == :Optimal
        @test isapprox(MPB.getobjval(m), 2.75)
        @test norm(MPB.getsolution(m) - [.75, 1.]) < tol
        if duals
            @test norm(MPB.getdual(m) - [0, 0, .125, .125*sqrt(2), .125, 2/3, 0, 0, 0, 0, 0]) < tol
            @test norm(MPB.getvardual(m)) < tol
        end
    end
end
