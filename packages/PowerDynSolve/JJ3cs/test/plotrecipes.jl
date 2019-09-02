begin
    using PowerDynBase
    using PowerDynSolve
    using RecipesBase
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
# test the helper functions
@test PowerDynSolve.tslabel(:bla, 3) == "bla3"
@test PowerDynSolve.tslabel.(:bla, [3,4]) == ["bla3", "bla4"]
@test PowerDynSolve.tstransform(zeros(4)) == zeros(4)
@test PowerDynSolve.tstransform(zeros(2, 6)) == zeros(6, 2)
@test_throws MethodError PowerDynSolve.tstransform(zeros(2,4,6))
end

let
KW = Dict{Symbol, Any}
RecipesBase.is_key_supported(::Symbol) = true
# generate some solution
parnodes = [SwingEqLVS(H=1., P=-1, D=1, Ω=50, Γ=20, V=1), SwingEqLVS(H=1., P=-1, D=1, Ω=50, Γ=20, V=1)]
LY = [1.0im -im; -im im]
grid = GridDynamics(parnodes, LY)
start = State(grid, rand(SystemSize(grid)))
p = GridProblem(start, (0.,10.))
sol = solve(p)
@test_throws PowerDynSolve.PowerDynamicsPlottingError RecipesBase.apply_recipe(KW(), sol, 1:2, :int, 1)
for callargs in [(:v,), (:φ,), (:p,), (:q,), (:ω,)]
    # callargs = (:v,) # for dev only

    data_list = RecipesBase.apply_recipe(KW(), sol, : , callargs...)
    @test length(data_list) == 1
    @test data_list[1].plotattributes == KW()
    plotargs = data_list[1].args
    @test length(plotargs) == 2 + length(callargs)
    @test plotargs[1] === sol
    @test plotargs[2] == Base.OneTo(length(parnodes)) # range of all nodes
    @test plotargs[3:end] == callargs

    data_list = RecipesBase.apply_recipe(KW(), plotargs...)
    @test length(data_list) == 1
    @test data_list[1].plotattributes == KW(:tres => PowerDynSolve.PLOT_TTIME_RESOLUTION, :label => PowerDynSolve.tslabel.(callargs..., 1:length(Nodes(sol))), :xlabel => "t")
    plotargs = data_list[1].args
    @test plotargs[1] == tspan(sol, PowerDynSolve.PLOT_TTIME_RESOLUTION)
    @test plotargs[2] == PowerDynSolve.tstransform(sol(tspan(sol, PowerDynSolve.PLOT_TTIME_RESOLUTION), 1:length(parnodes), callargs...))
    @test size(plotargs[2]) == (PowerDynSolve.PLOT_TTIME_RESOLUTION, length(parnodes))

    for nodenum = [1, 2]
        # nodenum = 1 # for dev only
        data_list = RecipesBase.apply_recipe(KW(), sol, nodenum, callargs...)
        @test length(data_list) == 1
        @test data_list[1].plotattributes == KW(:tres => PowerDynSolve.PLOT_TTIME_RESOLUTION, :label => PowerDynSolve.tslabel(callargs..., nodenum), :xlabel => "t")
        plotargs = data_list[1].args
        @test plotargs[1] == tspan(sol, PowerDynSolve.PLOT_TTIME_RESOLUTION)
        plotargs[2]
        sol(tspan(sol, PowerDynSolve.PLOT_TTIME_RESOLUTION), nodenum, callargs...)
        @test all(plotargs[2] .≈ sol(tspan(sol, PowerDynSolve.PLOT_TTIME_RESOLUTION), nodenum, callargs...))
    end
end

var = :v
nodeNumbers = 1:2
csol = CompositeGridSolution(sol, solve(GridProblem(start, (15., 25.))))
data_list = RecipesBase.apply_recipe(KW(), csol, nodeNumbers, var)
@test length(data_list) == 1
rdata = data_list[1]
@test rdata.plotattributes == KW(:tres => PowerDynSolve.PLOT_TTIME_RESOLUTION, :label => PowerDynSolve.tslabel.(var, nodeNumbers), :xlabel => "t", :removedNodes => ())
# compare whether the plot results of a CompositeGridSolution match the combination
# of the single grid solutions together
test_data_list = RecipesBase.apply_recipe.(Ref(KW()), csol, Ref(nodeNumbers), Ref(var))
test_tspan = vcat(test_data_list[1][1].args[1], test_data_list[2][1].args[1])
@test rdata.args[1] == test_tspan == vcat(tspan.(csol, PowerDynSolve.PLOT_TTIME_RESOLUTION)...)
test_plot_args = vcat(test_data_list[1][1].args[2], test_data_list[2][1].args[2])
@test rdata.args[2] == test_plot_args == vcat(broadcast((sol, t, n) -> PowerDynSolve.tstransform(sol(t, n, var)), csol, tspan.(csol, Ref(PowerDynSolve.PLOT_TTIME_RESOLUTION)), Ref(nodeNumbers))...)

nodeNumbers = 1:3
removedNodes = ((2,), (3,))
data_list = RecipesBase.apply_recipe(KW(:removedNodes => removedNodes), csol, nodeNumbers, var)
@test length(data_list) == 1
rdata = data_list[1]
@test rdata.plotattributes == KW(:tres => PowerDynSolve.PLOT_TTIME_RESOLUTION, :label => PowerDynSolve.tslabel.(var, nodeNumbers), :xlabel => "t", :removedNodes => removedNodes)

@test rdata.args[1] == test_tspan
@test all( rdata.args[2][1:PowerDynSolve.PLOT_TTIME_RESOLUTION,2] .=== fill(NaN, PowerDynSolve.PLOT_TTIME_RESOLUTION) )
@test all( rdata.args[2][(PowerDynSolve.PLOT_TTIME_RESOLUTION+1):end,3] .=== fill(NaN, PowerDynSolve.PLOT_TTIME_RESOLUTION) )
@test rdata.args[2][1:PowerDynSolve.PLOT_TTIME_RESOLUTION,[1,3]] == test_plot_args[1:PowerDynSolve.PLOT_TTIME_RESOLUTION,:]
@test rdata.args[2][(PowerDynSolve.PLOT_TTIME_RESOLUTION+1):end,1:2] == test_plot_args[(PowerDynSolve.PLOT_TTIME_RESOLUTION+1):end,:]


var = :v
nodeNumbers = 1:2
csol2 = CompositeGridSolution(csol, solve(GridProblem(start, (25., 30.))))
data_list = RecipesBase.apply_recipe(KW(), csol2, nodeNumbers, var)
@test length(data_list) == 1
rdata = data_list[1]
@test rdata.plotattributes == KW(:tres => PowerDynSolve.PLOT_TTIME_RESOLUTION, :label => PowerDynSolve.tslabel.(var, nodeNumbers), :xlabel => "t", :removedNodes => ())
# compare whether the plot results of a CompositeGridSolution match the combination
# of the single grid solutions together
test_data_list = RecipesBase.apply_recipe.(Ref(KW()), csol2, Ref(nodeNumbers), Ref(var))
test_tspan = vcat(test_data_list[1][1].args[1], test_data_list[2][1].args[1], test_data_list[3][1].args[1])
@test rdata.args[1] == test_tspan
@test rdata.args[2] == vcat(broadcast((sol, t, n) -> PowerDynSolve.tstransform(sol(t, n, var)), csol2, tspan.(csol2, Ref(PowerDynSolve.PLOT_TTIME_RESOLUTION)), Ref(nodeNumbers))...)

end
