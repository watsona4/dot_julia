# Validated from http://www.ams.jhu.edu/~castello/625.414/Handouts/FractionalProg.pdf

@testset "Simple example" begin
    lfp = LinearFractionalModel(solver=ClpSolver())
    x1 = @variable(lfp, basename="x1", lowerbound=0)
    x2 = @variable(lfp, basename="x2", lowerbound=0, upperbound=6)
    @constraint(lfp, -x1 + x2 <= 4)
    @constraint(lfp, 2x1 + x2 <= 14)
    @constraint(lfp, x2 <= 6)
    @numerator(lfp,  :Min, -2x1 + x2 + 2)
    @denominator(lfp,  x1 + 3x2 + 4)
    @test solve(lfp) == :Optimal
    @test getvalue(x1) ≈ 7.0
    @test getvalue(x2) ≈ 0.0
end
