using ConicNonlinearBridge
using MathProgBase
using Ipopt

using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays


if VERSION < v"0.7.0-"
    mpb_path = Pkg.dir("MathProgBase")
end

if VERSION > v"0.7.0-"
    mpb_path = joinpath(dirname(pathof(MathProgBase)), "..")
end


include(joinpath(mpb_path, "test", "conicinterface.jl"))

@testset "ConicNonlinearBridge Tests" begin

@testset "linear and exponential cone tests (remove_single_rows is $remove_single_rows)" for remove_single_rows in [true, false]
    solver = ConicNLPWrapper(nlp_solver=IpoptSolver(print_level=0), remove_single_rows=remove_single_rows)
    coniclineartest(solver; duals=false, tol=1e-6)
    conicEXPtest(solver; duals=false, tol=1e-6)
end

@testset "second-order cone tests (soc_as_quadratic is $soc_as_quadratic)" for soc_as_quadratic in [true, false]
    solver = ConicNLPWrapper(nlp_solver=IpoptSolver(print_level=0), soc_as_quadratic=soc_as_quadratic, disaggregate_soc=false)
    conicSOCRotatedtest(solver; duals=false, tol=1e-6)

    @testset "disaggregation tests (disaggregate_soc is $disaggregate_soc)" for disaggregate_soc in [true, false]
        solver = ConicNLPWrapper(nlp_solver=IpoptSolver(print_level=0), soc_as_quadratic=soc_as_quadratic, disaggregate_soc=disaggregate_soc)
        conicSOCtest(solver; duals=false, tol=1e-6)
    end
end

@testset "miscellaneous tests" begin
    # min 0x - 2y - 1z
    #  st  x == 1,
    #      x >= norm(y, z) as constraint cone
    #      x continuous, y binary, z integer
    solver = ConicNLPWrapper(nlp_solver=IpoptSolver(print_level=0))
    @test issubset([:Free, :Zero, :NonNeg, :NonPos, :SOC, :SOCRotated, :ExpPrimal], MathProgBase.supportedcones(solver))
    m = MathProgBase.ConicModel(solver)
    MathProgBase.loadproblem!(m, [0, -2, -1], [1 0 0; Matrix(-1.0I, 3, 3)], [1, 0, 0, 0], [(:Zero, 1), (:SOC, 2:4)], [(:Free, 1:3)])
    MathProgBase.setvartype!(m, [:Cont, :Bin, :Int])
    MathProgBase.setwarmstart!(m, [3, 4, 2])
    @test m.nlp_model.colCat[1:3] == [:Cont, :Bin, :Int]
    @test m.solution[1:3] == [3, 4, 2]
    @test MathProgBase.numvar(m) == 3
    @test MathProgBase.numconstr(m) == 4

    # make variables continuous and solve
    MathProgBase.setvartype!(m, [:Cont, :Cont, :Cont])
    MathProgBase.optimize!(m)
    @test MathProgBase.status(m) == :Optimal
    @test MathProgBase.getsolution(m) ≈ [1.0, 0.894427, 0.447214] atol=1e-4 rtol=1e-4
    @test MathProgBase.getobjval(m) ≈ -2.236067 atol=1e-4 rtol=1e-4
    MathProgBase.freemodel!(m)
end

end

