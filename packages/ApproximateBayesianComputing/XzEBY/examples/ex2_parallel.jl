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

@everywhere include(joinpath(Pkg.dir("ABC"),"src/composite.jl"))
@everywhere using CompositeDistributions
@everywhere import Compat.view

# Set Prior for Population Parameters
@everywhere d1 = Rayleigh(0.3)
@everywhere d2 = MvNormal([0.0, 1.0], ones(2))
@everywhere param_prior = CompositeDist( ContinuousDistribution[d1,d2] )

# Code to generate simulated data given array of model parameters
@everywhere num_data_default = 100
@everywhere num_outputs = 2
@everywhere function gen_data(theta::Array, n::Integer = num_data_default)
  data = Array(Float64,(3,n))
  data[1,:] = rand(Rayleigh(theta[1]),n)
  data[2:3,:] = rand(MvNormal(theta[2:3],ones(2)),n)
  return data
end

# Function to adjust originally proposed model parameters, so that they will be valid 
@everywhere function normalize_theta13_pos!(theta::Array)
 theta[1] = abs(theta[1])
 theta[3] = abs(theta[3])
 return theta
end

# Function to test if the proposed model parameter are valid
@everywhere function is_valid_theta13_pos(theta::Array)
  theta[1]>0.0  && theta[3]>0.0
end

# True Population Parameters
@everywhere theta_true = [0.3, 0.0, 1.0]

# Tell ABC what it needs to know for a simulation
@everywhere in_parallel = length(workers()) > 1 ? true : false
@everywhere abc_plan = abc_pmc_plan_type(gen_data,ABC.calc_summary_stats_mean_var,ABC.calc_dist_max, param_prior, is_valid=is_valid_theta13_pos,num_max_attempt=10000, in_parallel=in_parallel);

# Generate "true/observed "data"
data_true = gen_data(theta_true)   # Draw "real" data from same model as for analysis
ss_true = abc_plan.calc_summary_stats(data_true)
#println("theta= ",theta_true," ss= ",ss_true, " d= ", 0.)

# Run ABC simulation
@time pop_out = run_abc(abc_plan,ss_true,in_parallel=in_parallel);


#=
# Optional plotting of results
using PyPlot

hist(pop_out.weights*length(pop_out.weights));
hist(pop_out.dist);

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
