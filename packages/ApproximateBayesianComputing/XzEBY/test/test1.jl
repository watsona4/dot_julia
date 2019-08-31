# test1.jl 
# based on ex1.jl
using Distributions

function test1()
println("# Starting Test 1")
num_data_default = 200
gen_data_normal(theta::Array, n::Integer = num_data_default) = rand(Normal(theta[1],theta[2]),num_data_default)

normalize_theta2_pos(theta::Array) =  theta[2] = abs(theta[2])
is_valid_theta2_pos(theta::Array) =  theta[2]>0.0 ? true : false

theta_true = [0.0, 1.0]
param_prior = Distributions.MvNormal(theta_true,ones(length(theta_true)))

abc_plan = abc_pmc_plan_type(gen_data_normal,ABC.calc_summary_stats_mean_var,ABC.calc_dist_max, param_prior; 
                             target_epsilon=0.01,is_valid=is_valid_theta2_pos,num_max_attempt=10000);

num_param = 2
# Generate "observed" data 
data_obs = abc_plan.gen_data(theta_true)
ss_obs = abc_plan.calc_summary_stats(data_obs)
println("# Setting 'true' parameters of theta= ",theta_true)
println("# Generated 'observed' data with summary statistics = ",vec(ss_obs))
println("# Starting ABC-PMC run")
pop_out = run_abc(abc_plan,ss_obs;verbose=true);

println("# Results: ",mean(pop_out.theta[1,:]), " ",mean(pop_out.theta[2,:]))
if abs(mean(pop_out.theta[1,:]))>0.05
  return false
end
if abs(mean(pop_out.theta[2,:])-1)>0.05
  return false
end
return true
end
