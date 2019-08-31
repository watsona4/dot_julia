@compat abstract type abc_plan_type end

mutable struct abc_pmc_plan_saveable_type <: abc_plan_type
   gen_data::String
   calc_summary_stats::String
   calc_dist::String
   prior::Distribution
   make_proposal_dist::String
   normalize::String
   is_valid::String
   num_part::Int64
   num_max_attempt::Int64
   num_max_attempt_valid::Int64
   num_max_times::Int64
   num_dist_per_obs::Int64
   epsilon_init::Float64
   init_epsilon_quantile::Float64
   epsilon_reduction_factor::Float64
   target_epsilon::Float64
   tau_factor::Float64
   frac_rejects_save::Float64   # Not implemented yet
   param_active::Vector{Int64}   # Not fully tested yet
   adaptive_quantiles::Bool      # Not fully tested yet
   stop_on_decreasing_efficiency::Bool # Not implemented yet
   save_params::Bool   # Not implemented yet
   save_summary_stats::Bool   # Not implemented yet
   save_distances::Bool   # Not implemented yet
   in_parallel::Bool
end

mutable struct abc_pmc_plan_type <: abc_plan_type
   gen_data::Function
   calc_summary_stats::Function
   calc_dist::Function
   prior::Distribution
   make_proposal_dist::Function
   normalize::Function
   is_valid::Function
   num_part::Int64
   num_max_attempt::Int64
   num_max_attempt_valid::Int64
   num_max_times::Int64
   num_dist_per_obs::Int64
   epsilon_init::Float64
   init_epsilon_quantile::Float64
   epsilon_reduction_factor::Float64
   target_epsilon::Float64
   tau_factor::Float64
   frac_rejects_save::Float64   # Not implemented yet
   param_active::Vector{Int64}   # Not fully tested yet
   adaptive_quantiles::Bool      # Not fully tested yet
   stop_on_decreasing_efficiency::Bool # Not implemented yet
   save_params::Bool   # Not implemented yet
   save_summary_stats::Bool   # Not implemented yet
   save_distances::Bool   # Not implemented yet
   in_parallel::Bool


""" 
   abc_pmc_plan_type(gd::Function,css::Function,cd::Function,p::Distribution; <keyword arguements>)

Create a plan for an ABC simulations.

# Arguements 
- `gd`:  Generates the data
- `css`: Calculates the summary statistics from a simulated dataset
- `cd`:  Computes the distance between two sets of summary statistiscs
- `p`:   Prior distribution for model parameters
"""
function abc_pmc_plan_type(gd::Function,css::Function,cd::Function,p::Distribution;
     make_proposal_dist::Function = make_proposal_dist_gaussian_full_covar, param_active::Vector{Int64} = collect(1:length(Distributions.rand(p))),
     normalize::Function = noop, is_valid::Function = noop,
     num_part::Integer = 10*length(Distributions.rand(p))^2, num_max_attempt::Integer = 1000, num_max_attempt_valid::Integer = 50, num_max_times::Integer = 100, num_dist_per_obs::Int64 = 1, 
     epsilon_init::Float64 = 1.0, init_epsilon_quantile::Float64 = 0.75, epsilon_reduction_factor::Float64 = 0.9,
     target_epsilon::Float64 = 0.01, tau_factor::Float64 = 2.0,
     adaptive_quantiles::Bool = false, stop_on_decreasing_efficiency::Bool = false,
     save_params::Bool = true, save_summary_stats::Bool = false, save_distances::Bool = true, frac_rejects_save::Float64 = 0.0, in_parallel::Bool = false)
     @assert(num_part>=length(Distributions.rand(p)))
     @assert(num_max_attempt>=1)
     @assert(num_max_attempt_valid>=1)
     @assert(num_max_times>0)
     @assert(1<=num_dist_per_obs<=10000)
     @assert(epsilon_init>0.01)
     @assert(0<init_epsilon_quantile<=1.0)
     @assert(0.5<epsilon_reduction_factor<1.0)
     @assert(target_epsilon>0.0)
     @assert(1.0<=tau_factor<=4.0)
     @assert(0.0<=frac_rejects_save<=1.0)
     new(gd,css,cd,p,make_proposal_dist,normalize,is_valid, num_part,num_max_attempt,num_max_attempt_valid,num_max_times,num_dist_per_obs,epsilon_init, init_epsilon_quantile,epsilon_reduction_factor,target_epsilon,tau_factor,frac_rejects_save,param_active,adaptive_quantiles,stop_on_decreasing_efficiency,save_params,save_summary_stats,save_distances,in_parallel)
   end
end

function abc_pmc_plan_saveable_type(plan::abc_pmc_plan_type)
  abc_pmc_plan_saveable_type(string(plan.gen_data),string(plan.calc_summary_stats),string(plan.calc_dist),plan.prior,string(plan.make_proposal_dist),string(plan.normalize),string(plan.is_valid),plan.num_part,plan.num_max_attempt,plan.num_max_attempt_valid,plan.num_max_times,plan.num_dist_per_obs,plan.epsilon_init,plan.init_epsilon_quantile,plan.epsilon_reduction_factor,plan.target_epsilon,plan.tau_factor,plan.frac_rejects_save,plan.param_active,plan.adaptive_quantiles,plan.stop_on_decreasing_efficiency,plan.save_params,plan.save_summary_stats,plan.save_distances,plan.in_parallel)
end

# WARNING: This doesn't really work yet.  There seems to be some issue with the scope of the saved function and what's currently imported
function abc_pmc_plan_type(plan::abc_pmc_plan_saveable_type)
  abc_pmc_plan_saveable_type(eval(Symbol(plan.gen_data)),eval(Symbol(plan.calc_summary_stats)),eval(Symbol(plan.calc_dist)),plan.prior,eval(Symbol(plan.make_proposal_dist)),eval(Symbol(plan.normalize)),eval(Symbol(plan.is_valid)),plan.num_part,plan.num_max_attempt,plan.num_max_attempt_valid,plan.num_max_times,plan.num_dist_per_obs,plan.epsilon_init,plan.init_epsilon_quantile,plan.epsilon_reduction_factor,plan.target_epsilon,plan.tau_factor,plan.frac_rejects_save,plan.param_active,plan.adaptive_quantiles,plan.stop_on_decreasing_efficiency,plan.save_params,plan.save_summary_stats,plan.save_distances,plan.in_parallel)
end


mutable struct abc_log_type   # Not implemented yet
   theta::Array{Array{Float64,1},1}
   ss::Array{Any,1}
   dist::Array{Float64,1}
   epsilon::Array{Float64,1}
   generation_starts_at::Array{Int64,1}

   function abc_log_type(t::Array{Array{Float64,1},1}, ss::Array{Any,1}, d::Array{Float64,1}, eps::Array{Float64,1}, gsa::Array{Int64,1} = ones(Int64,1))
      @assert length(t) == length(ss) == length(d) == length(eps)
      new( t, ss, d, eps, gsa )
   end
end

function abc_log_type()
   abc_log_type( Array{Array{Float64,1}}(undef,0), Array{Any}(undef,0), Array{Float64}(undef,0), Array{Float64}(undef,0), Array{Int64}(undef,0) )
end


mutable struct abc_population_type_old # Deprecated, but kept for now, in case need to read in data from a file
   theta::Array{Float64,2}
   weights::Array{Float64,1}
   dist::Array{Float64,1}
   log::abc_log_type
   repeats::Array{Int64,1}

   function abc_population_type_old(t::Array{Float64,2}, w::Array{Float64,1}, d::Array{Float64,1}, l::abc_log_type = abc_log_type(), repeats::Array{Int64,1} = zeros(Int64,length(w)) )
      @assert(length(w)==length(d)==size(t,2)==length(repeats))
      new(t,w,d,l,repeats)
   end
end

mutable struct abc_population_type
   theta::Array{Float64,2}
   weights::Array{Float64,1}
   dist::Array{Float64,1}
   epsilon::Float64
   logpdf::Array{Float64,1}
   accept_log::abc_log_type
   reject_log::abc_log_type
   repeats::Array{Int64,1}

   function abc_population_type(t::Array{Float64,2}, w::Array{Float64,1}, d::Array{Float64,1}, eps::Float64, lp::Array{Float64,1} = ones(Float64,length(w))/length(w), la::abc_log_type = abc_log_type(), lr::abc_log_type = abc_log_type(), repeats::Array{Int64,1} = zeros(Int64,length(w)) )
      @assert(length(w)==length(d)==length(lp)==size(t,2)==length(repeats))
      new(t,w,d,eps,lp,la,lr,repeats)
   end
end

"""
   abc_population_type(num_param::Integer, num_particles::Integer; accept_log::abc_log_type = abc_log_type(), reject_log::abc_log_type = abc_log_type(), repeats::Array{Int64,1} = zeros(Int64,num_particles) )

num_param:  Number of model parameters for generating simulated data
num_particles: Number of particles for sequential importance sampler

Optional parameters:
accept_log: Log of accepted parameters/summary statistics/distances
reject_log: Log of rejected parameters/summary statistics/distances
repeats:    Array indicating which particles have been repeated from previous generation

"""
function abc_population_type(num_param::Integer, num_particles::Integer; accept_log::abc_log_type = abc_log_type(), reject_log::abc_log_type = abc_log_type(), repeats::Array{Int64,1} = zeros(Int64,num_particles) )
   abc_population_type(zeros(num_param,num_particles), zeros(num_particles), zeros(num_particles), 0.0, ones(Float64,num_particles)/num_particles, accept_log, reject_log, repeats)
end

