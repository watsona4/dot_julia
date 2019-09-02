begin
    using PowerDynBase
    using PowerDynOperationPoint
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
U1 = 1+5im
S2 = -2+3im
y = 2+1.5im
dynnodes = construct_node_dynamics.([SlackAlgebraic(U=U1), PQAlgebraic(S=S2)])
LY = [y -y; -y y ]
grid = GridDynamics(dynnodes, LY)
x = rand(SystemSize(grid))
dx = similar(x)
grid(dx, x, nothing, 0.) # evalute dx directly
 # evalute dx via RootFunction and then compare
root = RootFunction(grid)
@test dx ≈ root(x)
@test State(grid, dx) ≈ root(State(grid, x)) # testing state dispatch
end
