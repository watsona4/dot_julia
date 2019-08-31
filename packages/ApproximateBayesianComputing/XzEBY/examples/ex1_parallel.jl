if length(ARGS) >= 1
  nw = parse(ARGS[1])
  if nw >1
     addprocs(nw)
  end
else 
  addprocs()
end

import Distributions; @everywhere using Distributions
import ABC; @everywhere using ABC

# Set Prior for Population Parameters
@everywhere theta_true = [0.0, 1.0]
@everywhere param_prior = Distributions.MvNormal(theta_true,ones(length(theta_true)))

# Code to generate simulated data given array of model parameters
@everywhere num_data_default = 100
@everywhere gen_data_normal(theta::Array, n::Integer = num_data_default) = rand(Distributions.Normal(theta[1],theta[2]),num_data_default)

# Function to adjust originally proposed model parameters, so that they will be valid
@everywhere normalize_theta2_pos(theta::Array) =  theta[2] = abs(theta[2])

# Function to test if the proposed model parameter are valid
@everywhere is_valid_theta2_pos(theta::Array) =  theta[2]>0.0 ? true : false

# Tell ABC what it needs to know for a simulation
@everywhere in_parallel = length(workers()) > 1 ? true : false
@everywhere abc_plan = ABC.abc_pmc_plan_type(gen_data_normal,ABC.calc_summary_stats_mean_var,ABC.calc_dist_max, param_prior; is_valid=is_valid_theta2_pos,num_max_attempt=10000, in_parallel=in_parallel);

# Generate "true/observed data" and summary statistics
@everywhere data_true = abc_plan.gen_data(theta_true)
@everywhere ss_true = abc_plan.calc_summary_stats(data_true)
#println("theta= ",theta_true," ss= ",ss_true, " d= ", 0.)

# Run ABC simulation
@time pop_out = run_abc(abc_plan,ss_true;verbose=true,in_parallel=in_parallel);


#= 
# Optional plotting of results
using PyPlot

hist(pop_out.weights*length(pop_out.weights));
hist(pop_out.dist);

num_param = 2
num_grid_x = 100
num_grid_y = 100
limit = 1.0
x = collect(linspace(theta_true[1]-limit,theta_true[1]+limit,num_grid_x));
y = collect(linspace(theta_true[2]-limit,theta_true[2]+limit,num_grid_y));
z = zeros(Float64,(num_param,length(x),length(y)))
for i in 1:length(x), j in 1:length(y) 
    z[1,i,j] = x[i]
    z[2,i,j] = y[j]
end
z = reshape(z,(num_param,length(x)*length(y)))
zz = [ ABC.pdf(ABC.GaussianMixtureModelCommonCovar(pop_out.theta,pop_out.weights,ABC.cov_weighted(pop_out.theta',pop_out.weights)),vec(z[:,i])) for i in 1:size(z,2) ]
zz = reshape(zz ,(length(x),length(y)));
levels = [exp(-0.5*i^2)/sqrt(2pi^num_param) for i in 0:5];
PyPlot.contour(x,y,zz',levels);
plot(pop_out.theta[1,:],pop_out.theta[2,:],".");
=#
