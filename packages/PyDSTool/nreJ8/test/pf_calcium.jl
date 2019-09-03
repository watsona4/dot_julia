using ParameterizedFunctions, PyDSTool, Base.Test

f = @ode_def_bare Calcium begin
  dv = ( i + gl * (vl - v) - gca * 0.5 * (1 + tanh( (v-v1)/v2 )) * (v-vca) )/c
  dw = v-w
end vl vca i gl gca c v1 v2
p = [-60,120,0.0,2,4,20,-1.2,18]
u0 = [0;0]
tspan = [0;30]

dsargs = build_ode(f,u0,tspan,p)
#Solve the ODE
d = solve_ode(dsargs)
#using Plots
#plot(d[:t],d[:v])

ode = ds[:Generator][:Vode_ODEsystem](dsargs)
ode[:set](pars = Dict("i"=>-220))
ode[:set](ics  = Dict("v"=>-170))
PC = ds[:ContClass](ode)

bif = bifurcation_curve(PC,"EP-C",["i"],
                        max_num_points=450,
                        max_stepsize=2,min_stepsize=1e-5,
                        stepsize=2e-2,loc_bif_points="all",
                        save_eigen=true,name="EQ1",
                        print_info=true,calc_stab=true)

@test length(bif.changes) == 2

#=
using Plots
plot(bif,(:i,:v))
=#
