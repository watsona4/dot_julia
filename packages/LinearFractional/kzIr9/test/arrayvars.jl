@testset "Array variables" begin
    lfp = LinearFractionalModel(solver=ClpSolver())
    a = [-2, 0]
    x = @variable(lfp, [i=1:2], basename="x", lowerbound=0)
    @constraint(lfp, x[2] <= 6)
    @constraint(lfp, -x[1] + x[2] <= 4)
    @constraint(lfp, 2x[1] + x[2] <= 14)
    @numerator(lfp,  :Min, sum(a[i] * x[i] for i in 1:2) + 2)
    @denominator(lfp,  x[1] + 3x[2] + 4)
    @test solve(lfp) == :Optimal
    @test all(getvalue(x) .≈ [7.0, 0.0])
end


@testset "Array constraints" begin
    lfp = LinearFractionalModel(solver=ClpSolver())
    x = @variable(lfp, [i=1:2], basename="x")
    a = [2, 1]
    upbs = [4, 20]
    lbs = [-4, -20]
    @constraint(lfp, [i=1:2], x[i] <= upbs[i])
    @constraint(lfp, [i=1:2], x[i] >= lbs[i])
    @numerator(lfp,  :Min, sum(a[i] * x[i] for i in 1:2) + 2)
    @denominator(lfp,  -x[1] + 20*x[2] + 4)
    @test solve(lfp) == :Optimal
    @test all(getvalue(x) .≈ [-4.0, -0.2])
end


@testset "Match LP" begin
    lfp = LinearFractionalModel(solver=ClpSolver())
    x = @variable(lfp, [i=1:2], basename="x")
    a = [4, 2]
    upbs = [4, 20]
    lbs = [-1, -10]
    @constraint(lfp, x[1] + x[2] <= 5.0)
    @constraint(lfp, x[1] - 2*x[2] >= 10.0)
    @constraint(lfp, [i=1:2], x[i] <= upbs[i])
    @constraint(lfp, [i=1:2], x[i] >= lbs[i])
    @numerator(lfp,  :Min, sum(a[i] * x[i] for i in 1:2))
    @denominator(lfp,  sum(x))
    solve(lfp)

    m = Model(solver=ClpSolver())
    xm = @variable(m, [i=1:2], basename="x")
    a = [4, 2]
    upbs = [4, 20]
    lbs = [-1,-10]
    @constraint(m, xm[1] + xm[2] <= 5.0)
    @constraint(m, xm[1] - 2*xm[2] >= 10.0)
    @constraint(m, [i=1:2], xm[i] <= upbs[i])
    @constraint(m, [i=1:2], xm[i] >= lbs[i])
    @constraint(m, sum(xm) == 1)
    @objective(m,  :Min, sum(a[i] * xm[i] for i in 1:2))
    solve(m)
    @test getvalue(xm) ≈ getvalue([xi.var for xi in x])
    @test getobjectivevalue(lfp) ≈ getobjectivevalue(m)
end



@testset "Constant denominator" begin
    lfp = LinearFractionalModel(solver=ClpSolver())
    x = @variable(lfp, [i=1:2], basename="x")
    a = [4, 2]
    upbs = [4, 20]
    lbs = [-1, -10]
    @constraint(lfp, x[1] + x[2] <= 5.0)
    @constraint(lfp, x[1] - 2*x[2] >= 10.0)
    @constraint(lfp, [i=1:2], x[i] <= upbs[i])
    @constraint(lfp, [i=1:2], x[i] >= lbs[i])
    @numerator(lfp,  :Min, sum(a[i] * x[i] for i in 1:2))
    @denominator(lfp,  5.0)
    solve(lfp)

    m = Model(solver=ClpSolver())
    xm = @variable(m, [i=1:2], basename="x")
    a = [4, 2]
    upbs = [4, 20]
    lbs = [-1,-10]
    @constraint(m, xm[1] + xm[2] <= 5.0)
    @constraint(m, xm[1] - 2*xm[2] >= 10.0)
    @constraint(m, [i=1:2], xm[i] <= upbs[i])
    @constraint(m, [i=1:2], xm[i] >= lbs[i])
    @objective(m,  :Min, sum(a[i] * xm[i] for i in 1:2))
    solve(m)
    @test getvalue(xm) ≈ getvalue(x)
    @test getobjectivevalue(lfp) ≈ getobjectivevalue(m)/5.0
end


@testset "Misc array features" begin
    ## dot should work
    lfp = LinearFractionalModel(solver=ClpSolver())
    a = [-2, 0]
    x = @variable(lfp, [i=1:2], basename="x", lowerbound=0)
    @constraint(lfp, x[2] <= 6)
    @constraint(lfp, -x[1] + x[2] <= 4)
    @constraint(lfp, 2x[1] + x[2] <= 14)
    @numerator(lfp,  :Min, dot(a, x) + 2)
    @denominator(lfp,  x[1] + 3x[2] + 4)
    @test solve(lfp) == :Optimal
    @test all(getvalue(x) .≈ [7.0, 0.0])
end
