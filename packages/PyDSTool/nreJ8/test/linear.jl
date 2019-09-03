using PyDSTool, PyCall

ics = Dict("x"=>1,"y"=>0.4)
pars = Dict("k"=>0.1,"m"=>0.5)
x_rhs = "y"
y_rhs = "-k*x/m"
vars = Dict("x"=>x_rhs,"y"=>y_rhs)
tspan = [0,30]
# keys()...

dsargs = build_ode("SHM",ics,pars,vars,tspan)
d = solve_ode(dsargs)

#using Plots
#plot(d[:t],[d[:x],d[:y]])
