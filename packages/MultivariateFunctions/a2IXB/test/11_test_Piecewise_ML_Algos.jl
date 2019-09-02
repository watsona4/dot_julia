using MultivariateFunctions
using Random
using DataFrames
using Distributions
using DataStructures

Random.seed!(1992)
nObs = 1000
dd = DataFrame()
dd[:x] = rand( Normal(),nObs) + 0.1 .* rand( Normal(),nObs)
dd[:z] = rand( Normal(),nObs) + 0.1 .* rand( Normal(),nObs)
dd[:w] = (0.5 .* rand( Normal(),nObs)) .+ 0.7.*(dd[:z] .- dd[:x]) + 0.1 .* rand( Normal(),nObs)
dd[:y] = (dd[:x] .*dd[:w] ) .* (dd[:z] .- dd[:w]) .+ dd[:x] + rand( Normal(),nObs)
dd[7,:y] = 1.0
y = :y
x_variables = Set{Symbol}([:w, :x, :z])

dd2 = deepcopy(dd)
dd2[dd2[:x] .< 0.0, :y] = 2.7
dd2[(dd2[:x] .> 0.0) .& (dd2[:w] .> 0.0), :y] = 1.3
dd2[(dd2[:x] .> 0.0) .& (dd2[:w] .< 0.0), :y] = 1.1

# Recursive Partitioning
rp_1, rp_reg_1 = create_recursive_partitioning(dd, y, x_variables, 3; rel_tol = 1e-3)
rp_2, rp_reg_2 = create_recursive_partitioning(dd, y, x_variables, 3; rel_tol = 1e-10)
SSR_1 = sum((rp_reg_1.rr.mu .- rp_reg_1.rr.y) .^ 2)
rp_3, rp_reg_3 = create_recursive_partitioning(dd, y, x_variables, 4; rel_tol = 1e-3)
SSR_3 = sum((rp_reg_3.rr.mu .- rp_reg_3.rr.y) .^ 2)
SSR_3 <= SSR_1
rp_4, rp_reg_4 = create_recursive_partitioning(dd, y, x_variables, 7; rel_tol = 1e-3)
SSR_4 = sum((rp_reg_4.rr.mu .- rp_reg_4.rr.y) .^ 2)
SSR_4 <= SSR_3
# Where we have piecewise constant data.
rp_21, rp_reg_21 = create_recursive_partitioning(dd2, y, x_variables, 3; rel_tol = 1e-3)
sum(abs.(evaluate(rp_21, dd2) .- dd2[:y])) < 1e-10

# MARS Spline
rp_1, rp_reg_1 = create_mars_spline(dd, y, x_variables, 3; rel_tol = 1e-3)
dd3 = deepcopy(dd)
dd3[:y] = 8.0 .* max.(0.0, dd3[:x] .+ 3.2) .+ 2.0 .* max.(0.0, dd3[:z] .+ 2.4) .+ 2.7 .* max.(0.0, dd3[:w] .- 1.2)
rp_32, rp_reg_32 = create_mars_spline(dd3, y, x_variables, 7; rel_tol = 1e-3)
sum(abs.(evaluate(rp_32, dd3) .- dd3[:y])) < 1e-08
dd4 = deepcopy(dd)
dd4[:y] = 1.0 .* max.(0.0, dd4[:x] .+ 3.2) .+ 2.0 .* max.(0.0, dd4[:z] .+ 2.4) .* max.(0.0, dd4[:w] .- 1.2)
rp_41, rp_reg_41 = create_mars_spline(dd4, y, x_variables, 7; rel_tol = 1e-3)
rp_41_RSS = sum(abs.(evaluate(rp_41, dd4) .- dd4[:y]))
rp_41_RSS < 0.05 # Here we dont get a great result. Because first it splits but w and then z so both are out of whack.
rp_41_5, rp_reg_41_5 = create_mars_spline(dd4, y, x_variables, 3; rel_tol = 1e-3)
reg_41_5_RSS = sum(abs.(evaluate(rp_41_5, dd4) .- dd4[:y]))

# Trim number of functions
trimmed_rp_41_fin, trimmed_rp_reg_41_fin = trim_mars_spline(dd4, y, rp_41; final_number_of_functions = 5)
reg_41_RSS_trimmed_to_five = sum(abs.(evaluate(trimmed_rp_41_fin, dd4) .- dd4[:y]))
reg_41_RSS_trimmed_to_five < reg_41_5_RSS # Because building a bigger model and then trimming should probably lead to lower RSS
reg_41_RSS_trimmed_to_five > rp_41_RSS # Because trimmed model should have higher RSS
# Maximum increase in RSS
trimmed_rp_41_maxinc, trimmed_rp_reg_41_maxinc = trim_mars_spline(dd4, y, rp_41; maximum_increase_in_RSS = 5.0)
trimmed_rp_41_maxrss, trimmed_rp_reg_41_maxrss = trim_mars_spline(dd4, y, rp_41; maximum_RSS = 100.0)
trimmed_rp_41_maxrss_trimmed = sum(abs.(evaluate(trimmed_rp_41_maxrss, dd4) .- dd4[:y]))
trimmed_rp_41_maxrss_trimmed < 100.0
