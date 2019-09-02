using ODEInterfaceDiffEq, DiffEqProblemLibrary, DiffEqBase
using Test

using DiffEqProblemLibrary.ODEProblemLibrary: importodeproblems; importodeproblems()
import DiffEqProblemLibrary.ODEProblemLibrary: prob_ode_linear

prob = prob_ode_linear
sol =solve(prob,dopri5(),dt=1//2^(4))

sol =solve(prob,dopri5())
#plot(sol,plot_analytic=true)
sol =solve(prob,dopri5(),save_everystep=false)
@test sol.t == [0.0,1.0]

sol =solve(prob,dopri5(),saveat = 0.1)
@test sol.t == collect(0:0.1:1)

sol = solve(prob,dopri5(),save_on=false,save_start=false)
@test isempty(sol.t) && isempty(sol.u)
