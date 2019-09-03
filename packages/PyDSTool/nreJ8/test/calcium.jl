using PyDSTool, DataStructures

name = "Calcium channel model"
pars = Dict{String,Any}(
          "vl"=> -60,
          "vca"=> 120,
          "i" => 0,
          "gl" => 2,
          "gca" => 4,
          "c" => 20,
          "v1" => -1.2,
          "v2" => 18)
vars = Dict{String,Any}(
          "v" => "( i + gl * (vl - v) - gca * 0.5 * (1 + tanh( (v-v1)/v2 )) * (v-vca) )/c",
          "w" => "v-w")
ics = Dict{String,Any}(
          "v" => 0,
          "w" => 0)
tdomain = [0;30]


dsargs = build_ode(name,ics,pars,vars,tdomain)

#Solve the ODE
#d = solve_ode(dsargs)
#using Plots
#plot(d[:t],d[:v])

#Bifurcation Plots
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

bif = bifurcation_curve(PC,"LP-C",["i","gca"],
                        max_num_points=200,initpoint="EQ1:LP2",
                        max_stepsize=2,min_stepsize=1e-5,
                        stepsize=2e-2,loc_bif_points="CP",
                        save_eigen=true,name="SN1",
                        print_info=true,calc_stab=true,
                        solver_sequence=[:forward,:backward])

@test length(bif.changes) == 0

#=
using Plots
plot(bif,(:i,:gca))
=#
