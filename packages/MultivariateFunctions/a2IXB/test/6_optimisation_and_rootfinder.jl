using MultivariateFunctions
using Dates
tol = 1e-13


tol = 10*eps()
constant    = PE_Unit()
linear      = PE_Unit(0.0,2.0,1)
quadratic   = PE_Unit(0.0,1.0,2)
exponential = PE_Unit(2.0,2.0,0)
higher      = PE_Unit(2.0,2.0,2)

f = PE_Function(1.8, Dict([:w, :x, :y, :z] .=> [linear, quadratic, exponential, higher]))

degree = 2
dimensions = underlying_dimensions(f)
g = all_derivatives(f, degree, dimensions)
coordinates = Dict{Symbol,Float64}([:w, :x, :y, :z] .=> [1.1, 2.1, 3.3, 4.0])
abs(evaluate(g[Dict{Symbol,Int}([:w,:z] .=> [1,1])], coordinates) - evaluate(derivative(f, Dict{Symbol,Int}([:w,:z] .=> [1,1])), coordinates) ) < 1e-10

# Testing uniroot
step_size = 1.0
max_iters = 40
convergence_tol = 1e-10
print_reports = false
initial_guess = coordinates
root_coordinates, root_value, root_convergence  = uniroot(f, initial_guess; step_size = step_size, max_iters = max_iters, convergence_tol = convergence_tol, print_reports = print_reports)
evaluate(f, root_coordinates) < tol
initial_guess = Dict{Symbol,Float64}([:w, :x, :y, :z] .=> [10.0, 5.0, 0.2, 1.2])
root_coordinates2, root_value2, root_convergence2 = uniroot(f, initial_guess; step_size = step_size, max_iters = max_iters, convergence_tol = convergence_tol, print_reports = print_reports)
evaluate(f, root_coordinates2) < tol
# Test we have found a different root:
sum(values(merge(-,root_coordinates, root_coordinates2))) > 1.0

print_reports = false
maximise = true
initial_guess = coordinates
opt_coordinates , opt_value , opt_convergence, hessian_det_sign  = find_local_optima(f, initial_guess; step_size = step_size, max_iters = max_iters, convergence_tol = convergence_tol, print_reports = print_reports)
opt_convergence
coordinates2 = Dict{Symbol,Float64}([:w, :x, :y, :z] .=> [1.9, 4.1, -4.0, 4.0])
opt_coordinates2, opt_value2, opt_convergence2, hessian_det_sign2 = find_local_optima(f, coordinates2; step_size = step_size, max_iters = max_iters, convergence_tol = convergence_tol, print_reports = print_reports)
opt_convergence2
