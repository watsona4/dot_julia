begin
    using PowerDynBase
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

# sub types of AbstractTimeSpan
let
_ts1 = (1, 2)
# ensure integers are used as input so the test for the type compatibility
# with DifferentialEquations.jl below makes sense
@test isa(_ts1, Tuple{Int, Int})

# TimeSpan
tspan1 = convert(PowerDynSolve.TimeSpan, _ts1)
@test issorted(tspan1)
@test PowerDynSolve.iscontinuous(tspan1)
# check types to be compatible with DifferentialEquations.jl
@test isa(tspan1.tBegin, PowerDynSolve.Time)
@test isa(tspan1.tEnd, PowerDynSolve.Time)
# check that only correct time spans are created
@test_throws MethodError convert(PowerDynSolve.TimeSpan, (1.0,))
@test_throws MethodError convert(PowerDynSolve.TimeSpan, 1.0)
@test_throws MethodError convert(PowerDynSolve.TimeSpan, (1.0, 2.0, 3.0))
# check methods
@test 1 ∈ tspan1 # left border
@test 2 ∈ tspan1 # right border
@test 1.5 ∈ tspan1 # within
@test 0.5 ∉ tspan1
@test 2.5 ∉ tspan1
@test convert(Tuple, tspan1) == (1., 2.)

# MultipleTimeSpans
tspan2 = convert(PowerDynSolve.MultipleTimeSpans, ((1, 2), (0.1, 1.5)))
@test !issorted(tspan2)
@test !PowerDynSolve.iscontinuous(tspan2)
# check methods
@test 1 ∈ tspan2
@test 2 ∈ tspan2
@test 1.5 ∈ tspan2
@test 0.5 ∈ tspan2 # is only in the second set
@test 0.1 ∈ tspan2
@test 0. ∉ tspan2
@test 2.5 ∉ tspan2
@test convert(Tuple, tspan2) == ((1., 2.), (0.1, 1.5))
@test convert(Tuple{Vararg{PowerDynSolve.TimeSpan}}, tspan2) == (PowerDynSolve.TimeSpan(1., 2.), PowerDynSolve.TimeSpan(0.1, 1.5))
# test the iterate method:
@test (tspan2...,) == (PowerDynSolve.TimeSpan(1., 2.), PowerDynSolve.TimeSpan(0.1, 1.5))

# sorted but not continuous
tspan3 = convert(PowerDynSolve.MultipleTimeSpans, ((1, 2), (2, 3), (4, 5)))
@test issorted(tspan3)
@test !PowerDynSolve.iscontinuous(tspan3)
# check methods
@test 1 ∈ tspan3
@test 2 ∈ tspan3
@test 1.5 ∈ tspan3
@test 3 ∈ tspan3
@test 2.5 ∈ tspan3
@test 4 ∈ tspan3
@test 5 ∈ tspan3
@test 4.5 ∈ tspan3
@test 0.5 ∉ tspan3
@test 3.5 ∉ tspan3
@test 5.5 ∉ tspan3
@test convert(Tuple, tspan3) == ((1., 2.), (2., 3.), (4., 5))
@test tspan3[1] == PowerDynSolve.TimeSpan(1, 2)
@test tspan3[2] == PowerDynSolve.TimeSpan(2, 3)
@test tspan3[3] == PowerDynSolve.TimeSpan(4, 5)
@test tspan3[1:2] == (PowerDynSolve.TimeSpan(1, 2), PowerDynSolve.TimeSpan(2, 3))
@test tspan3[2:end] == (PowerDynSolve.TimeSpan(2, 3), PowerDynSolve.TimeSpan(4, 5))
@test tspan3[:] == (PowerDynSolve.TimeSpan(1, 2), PowerDynSolve.TimeSpan(2, 3), PowerDynSolve.TimeSpan(4, 5))
@test findfirst(1, tspan3) == 1
@test findfirst(1.5, tspan3) == 1
@test findfirst(2, tspan3) == 1
@test findfirst(2.5, tspan3) == 2
@test findfirst(3, tspan3) == 2
@test findfirst(4, tspan3) == 3
@test findfirst(4.5, tspan3) == 3
@test findfirst(5, tspan3) == 3
@test findfirst(0.5, tspan3) === nothing
@test findfirst(3.5, tspan3) === nothing
@test findfirst(5.5, tspan3) === nothing

# sorted and continuous
tspan4 = convert(PowerDynSolve.MultipleTimeSpans, ((1, 2), (2, 3), (3, 6)))
@test issorted(tspan4)
@test PowerDynSolve.iscontinuous(tspan4)
@test convert(PowerDynSolve.TimeSpan, tspan4) == PowerDynSolve.TimeSpan(1, 6)
end

# GridSolution
let
parnodes = [SwingEqLVS(H=1., P=-1, D=1, Ω=50, Γ=20, V=1), SwingEqLVS(H=1., P=-1, D=1, Ω=50, Γ=20, V=1)]
LY = [1.0im -im; -im im]
grid = GridDynamics(parnodes, LY)
start = State(grid, rand(SystemSize(grid)))
p = GridProblem(start, (0.,10.))
sol = solve(p)
@test (0., 10.) == tspan(sol)
@test (range(0, stop=10, length=1_000) .≈ tspan(sol, 1_000)) |> all
ts = tspan(sol, 10_000)
for t in [ts, 0.1], n in [1:2, :, 1, 2]
    if n == (:)
        result_size = (2, size(t)...)
    else
        result_size = (size(n)..., size(t)...)
    end
    for syms=[(:u,), (:i,), (:p,), (:v,), (:int, 1), (:ω,) ]
        @test size(sol(t, n, syms...)) == result_size
    end
    @test sol(t, n, :int, 1) == sol(t, n, :ω)
end
@test_nowarn sol(ts, :, :int, [1, 1]) # access the frequencies

# check the extraction of states
@test_nowarn @test isa(sol(5.), PowerDynBase.AbstractState)
@test sol(:initial) == start
@test_nowarn @test isa(sol(:final), PowerDynBase.AbstractState)
@test_throws MethodError sol(:something_else)
end

# CompositeGridSolution of 2 GridSolution
let
function exampleRun(parnodes, ts)
    LY = [1.0im -im; -im im]
    grid = GridDynamics(parnodes, LY)
    start = State(grid, rand(SystemSize(grid)))
    p = GridProblem(start, ts)
    solve(p)
end

ts1 = (0.,10.)
ts2 = (15., 25.)
parnodes1 = [SwingEqLVS(H=1., P=-1, D=1, Ω=50, Γ=20, V=1), SwingEqLVS(H=1., P=-1, D=1, Ω=50, Γ=20, V=1)]
parnodes2 = [SwingEqLVS(H=1., P=-1, D=1, Ω=50, Γ=20, V=1), SwingEqLVS(H=1., P=0, D=1, Ω=50, Γ=20, V=1)]
sol1 = exampleRun(parnodes1, ts1)
sol2 = exampleRun(parnodes2, ts2)
ssh = PowerDynSolve.SubSolutionHandler((sol1, sol2))
@test_throws PowerDynSolve.GridSolutionError ssh(nothing)
@test ssh(nothing, missingIfNotFound=true) === missing

tArray1 = LinRange(ts1[1], ts1[2], 100)
tArray2 = LinRange(ts2[1], ts2[2], 300)

@test ssh(1, tArray1, :, :u) == sol1(tArray1, :, :u)
@test ssh(1, tArray1, 1, :u) == sol1(tArray1, 1, :u)
@test ssh(1, tArray1, :, :ω) == sol1(tArray1, :, :ω)
@test ssh(2, tArray2, :, :u) == sol2(tArray2, :, :u)
@test ssh(2, tArray2, :, :ω) == sol2(tArray2, :, :ω)

csol = CompositeGridSolution(sol1, sol2)
@test_nowarn PowerDynSolve.SubSolutionHandler((csol, sol1))
@test_throws PowerDynSolve.GridSolutionError CompositeGridSolution(csol, sol1)

@test csol(tArray1, 1:2, :u) == sol1(tArray1, :, :u)
@test csol(tArray1, 1, :u) == sol1(tArray1, 1, :u)
@test csol(tArray1, 1:2, :ω) == sol1(tArray1, :, :ω)
@test csol(tArray2, 1:2, :u) == sol2(tArray2, :, :u)
@test csol(tArray2, 1:2, :ω) == sol2(tArray2, :, :ω)

@test_throws PowerDynSolve.GridSolutionError csol(tArray1, :, :u)

@test_throws PowerDynSolve.GridSolutionError csol([10, 11, 12], 1, :u)
@test all( csol([11, 12, 13], 1:2, :u, missingIfNotFound=true) .=== Array{Missing}(missing, 2, 3) )
@test all( csol([11, 12, 13], 1, :u, missingIfNotFound=true) .=== Array{Missing}(missing, 3) )
@test all( csol(11, 1:2, :u, missingIfNotFound=true) .=== Array{Missing}(missing, 2) )
@test csol(11, 1, :u, missingIfNotFound=true) .=== missing

@test_throws BoundsError csol(tArray1, 3, :u)
end
