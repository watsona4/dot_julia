begin
    using PowerDynBase
    using PowerDynOperationPoint
    using PowerDynSolve
    using Random
    using Test
    @show random_seed = 1234
    Random.seed!(random_seed)
end

################################################################################
# no indentation to easily run it in atom but still have the let environments
# for the actual test runs
################################################################################

let
LY = [1.0im -im; -im im]
grid1 = GridDynamics([SwingEqLVS(H=1., P=-1, D=1, Ω=50, Γ=20, V=1), SwingEqLVS(H=1., P=-1, D=1, Ω=50, Γ=20, V=1)], LY)
start1 = State(grid1, rand(SystemSize(grid1)))
grid2 = GridDynamics([SwingEqLVS(H=1., P=-2, D=1, Ω=50, Γ=20, V=1), SwingEqLVS(H=1., P=-1, D=1, Ω=50, Γ=20, V=1)], LY)
@test grid1 != grid2
@test_throws AssertionError GridProblem(grid2, start1, (0.,10.))
@test_throws AssertionError solve(grid2, start1, (0.,10.))
end

let
parnodes = [SwingEqLVS(H=1., P=-1, D=1, Ω=50, Γ=20, V=1), SwingEqLVS(H=1., P=-1, D=1, Ω=50, Γ=20, V=1)]
LY = [1.0im -im; -im im]
grid = GridDynamics(parnodes, LY)
start = State(grid, rand(SystemSize(grid)))
p = @test_nowarn GridProblem(start, (0.,10.))
sol = @test_nowarn solve(p)
@test sol.dqsol.retcode == :Success
@test Nodes(sol) === Nodes(grid)
@test_broken false # it currently runs the integration, but it should be checked where it goes
end

let
parnodes = [SlackAlgebraic(U=1.), SwingEqLVS(H=1., P=-1, D=1, Ω=50, Γ=20, V=1)]
LY = [1.0im -im; -im im]
grid = GridDynamics(parnodes, LY)
start = State(grid, rand(NetworkRHS(grid) |> SystemSize))
fp = getOperationPoint(start)
@test abs(fp[2, :int, 1]) < 1e-8 # there should be no frequency deviation at the fixed-point
start = copy(fp)
start[2, :int, 1] = 0.1 # small frequency perturbation
p = @test_nowarn GridProblem(start, (0.,10.))
sol = @test_nowarn solve(p)
@test sol.dqsol.retcode == :Success
@test Nodes(sol) === Nodes(grid)
@test_broken false # check whether it goes back to the fixed point
end
