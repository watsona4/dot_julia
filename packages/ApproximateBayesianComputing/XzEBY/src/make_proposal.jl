#if !@isdefined  PDMats
#   using PDMats 
#end

function calc_mean_stddev(pop::abc_population_type) #; param_active = nothing)
  theta_mean =  sum(pop.theta.*pop.weights',dims=2) # weighted mean for parameters
  theta_stddev = sqrt(var_weighted(pop.theta'.-theta_mean',pop.weights))  # scaled, weighted covar for parameters
  return (theta_mean,theta_stddev)
end


function make_proposal_dist_gaussian_full_covar(pop::abc_population_type, tau_factor::Float64; verbose::Bool = false, # param_active = nothing,
         max_maha_distsq_per_dim::Real = 4.0)
  theta_mean =  sum(pop.theta.*pop.weights',dims=2) # weighted mean for parameters
  rawtau = cov_weighted(pop.theta'.-theta_mean',pop.weights)  # scaled, weighted covar for parameters
  tau = tau_factor*rawtau
  #tau = tau_factor*make_matrix_pd(rawtau)
  if verbose
    println("theta_mean = ", theta_mean)
    println("pop.theta = ", pop.theta)
    println("pop.weights = ", pop.weights)
    println("tau = ", tau)
  end
  covar = PDMat(tau)
  max_maha_distsq = 4.0*size(theta_mean,1)
  if max_maha_distsq_per_dim > 0
     max_maha_distsq = max_maha_distsq_per_dim*size(theta_mean,1)
     sampler = GaussianMixtureModelCommonCovarTruncated(pop.theta,pop.weights,covar,max_maha_distsq)
  else
     sampler = GaussianMixtureModelCommonCovar(pop.theta,pop.weights,covar)
  end
  return sampler
end

function make_proposal_dist_gaussian_diag_covar(pop::abc_population_type, tau_factor::Float64; verbose::Bool = false, # param_active = nothing, 
         max_maha_distsq_per_dim::Real = 4.0)
  theta_mean =  sum(pop.theta.*pop.weights',dims=2) # weighted mean for parameters
  tau = tau_factor*var_weighted(pop.theta'.-theta_mean',pop.weights)  # scaled, weighted covar for parameters
  if verbose
    println("theta_mean = ", theta_mean)
    println("pop.theta = ", pop.theta)
    println("pop.weights = ", pop.weights)
    println("tau = ", tau)
  end
  covar = PDiagMat(tau)
  max_maha_distsq = 4.0*size(theta_mean,1)
  if max_maha_distsq_per_dim > 0
      max_maha_distsq = max_maha_distsq_per_dim*size(theta_mean,1)
      sampler = GaussianMixtureModelCommonCovarTruncated(pop.theta,pop.weights,covar,max_maha_distsq)
  else
     sampler = GaussianMixtureModelCommonCovar(pop.theta,pop.weights,covar)
  end
  return sampler
end

function make_proposal_dist_gaussian_subset_full_covar(pop::abc_population_type, tau_factor::Float64; verbose::Bool = false, param_active::Vector{Int64} = collect(1:size(pop.covar,1)) )
  weights = ones(pop.weights)./length(pop.weights) # pop.weights
  #weights = pop.weights
  theta_mean =  sum(pop.theta.*weights',dims=2) # weighted mean for parameters
  rawtau = cov_weighted(pop.theta'.-theta_mean',weights)  # scaled, weighted covar for parameters
  tau = tau_factor*rawtau
  #tau = tau_factor*make_matrix_pd(rawtau)
  if verbose
    println("theta_mean = ", theta_mean)
    println("pop.theta = ", pop.theta)
    println("pop.weights = ", pop.weights)
    println("weights = ", weights)
    println("tau = ", tau)
  end
  covar = tau # PDMat(tau[param_active])
  sampler = GaussianMixtureModelCommonCovarSubset(pop.theta,weights,covar,param_active)
end

function make_proposal_dist_gaussian_subset_diag_covar(pop::abc_population_type, tau_factor::Float64; verbose::Bool = false, param_active::Vector{Int64} = collect(1:size(pop.covar,1)) )
  weights = ones(pop.weights)./length(pop.weights) # pop.weights
  theta_mean =  sum(pop.theta.*weights',dims=2) # weighted mean for parameters
  tau = tau_factor*var_weighted(pop.theta'.-theta_mean',weights)  # scaled, weighted covar for parameters
  if verbose
    println("theta_mean = ", theta_mean)
    println("pop.theta = ", pop.theta)
    println("pop.weights = ", pop.weights)
    println("weights = ", weights)
    println("tau = ", tau)
  end
  covar = tau
  sampler = GaussianMixtureModelCommonCovarSubset(pop.theta,weights,covar,param_active)
end

function make_proposal_dist_gaussian_rand_subset_full_covar(pop::abc_population_type, tau_factor::Float64; verbose::Bool = false, num_param_active::Integer = 2)
  nparam = size(pop.theta,1)
  if num_param_active == nparam
     param_active = 1:nparam
  else
     param_active = union(sample(1:size(pop.theta,1),num_param_active,replace=false))
     println("# Proposals to perturb parameters: ", param_active)
  end
  make_proposal_dist_gaussian_subset_full_covar(pop,tau_factor, verbose=verbose, param_active=param_active )
end

function make_proposal_dist_gaussian_rand_subset_diag_covar(pop::abc_population_type, tau_factor::Float64; verbose::Bool = false, num_param_active::Integer = 2)
  nparam = size(pop.theta,1)
  if num_param_active == nparam
     param_active = 1:nparam
  else
     param_active = union(sample(1:size(pop.theta,1),num_param_active,replace=false))
     println("# Proposals to perturb parameters: ", param_active)
  end
  make_proposal_dist_gaussian_subset_diag_covar(pop,tau_factor, verbose=verbose, param_active=param_active )
end

function make_proposal_dist_gaussian_rand_subset_neighbors_diag_covar(pop::abc_population_type, tau_factor::Float64; verbose::Bool = false, num_param_active::Integer = 2)
  nparam = size(pop.theta,1)
  if num_param_active == nparam
     param_active = 1:nparam
  else
     param_active_first = rand(1:nparam)
     param_active = collect(param_active_first:(param_active_first+num_param_active-1))
     for i in 1:length(param_active)
         if param_active[i] > nparam
            param_active[i] -= nparam
         end
     end 
     println("# Proposals to perturb parameters: ", param_active)
  end
  make_proposal_dist_gaussian_subset_diag_covar(pop,tau_factor, verbose=verbose, param_active=param_active )
end

function make_proposal_dist_gaussian_rand_subset_neighbors_full_covar(pop::abc_population_type, tau_factor::Float64; verbose::Bool = false, num_param_active::Integer = 2)
  nparam = size(pop.theta,1)
  if num_param_active == nparam
     param_active = 1:nparam
  else
     param_active_first = rand(1:nparam)
     param_active = collect(param_active_first:(param_active_first+num_param_active-1))
     for i in 1:length(param_active)
         if param_active[i] > nparam
            param_active[i] -= nparam
         end
     end 
     println("# Proposals to perturb parameters: ", param_active)
  end
  make_proposal_dist_gaussian_subset_full_covar(pop,tau_factor, verbose=verbose, param_active=param_active )
end


make_proposal_dist_gaussian_cycle_subset_neighbors_cycle_start_idx_next = 1
make_proposal_dist_gaussian_cycle_subset_neighbors_param_idx_next = make_proposal_dist_gaussian_cycle_subset_neighbors_cycle_start_idx_next

function make_proposal_dist_gaussian_cycle_subset_neighbors_diag_covar(pop::abc_population_type, tau_factor::Float64; verbose::Bool = false, num_param_active::Integer = 2)
  global make_proposal_dist_gaussian_cycle_subset_neighbors_param_idx_next, make_proposal_dist_gaussian_cycle_subset_neighbors_cycle_start_idx_next
  nparam = size(pop.theta,1)
  if num_param_active >= nparam
     param_active = 1:nparam
  else
     param_active_first = ( (make_proposal_dist_gaussian_cycle_subset_neighbors_param_idx_next-1) % nparam ) + 1
     param_active = collect(param_active_first:(param_active_first+num_param_active-1))
     for i in 1:length(param_active)
         if param_active[i] > nparam
            param_active[i] -= nparam
         end
     end 
     println("# Proposals to perturb parameters: ", param_active)
     make_proposal_dist_gaussian_cycle_subset_neighbors_param_idx_next += num_param_active
     if make_proposal_dist_gaussian_cycle_subset_neighbors_param_idx_next > nparam
        make_proposal_dist_gaussian_cycle_subset_neighbors_param_idx_next = make_proposal_dist_gaussian_cycle_subset_neighbors_cycle_start_idx_next
        make_proposal_dist_gaussian_cycle_subset_neighbors_cycle_start_idx_next = ( (make_proposal_dist_gaussian_cycle_subset_neighbors_cycle_start_idx_next) % nparam ) + 1
     end
  end
  make_proposal_dist_gaussian_subset_diag_covar(pop,tau_factor, verbose=verbose, param_active=param_active )
end

function make_proposal_dist_gaussian_cycle_subset_neighbors_full_covar(pop::abc_population_type, tau_factor::Float64; verbose::Bool = false, num_param_active::Integer = 2)
  global make_proposal_dist_gaussian_cycle_subset_neighbors_param_idx_next, make_proposal_dist_gaussian_cycle_subset_neighbors_cycle_start_idx_next
  nparam = size(pop.theta,1)
  if num_param_active == nparam
     param_active = 1:nparam
  else
     param_active_first = ( (make_proposal_dist_gaussian_cycle_subset_neighbors_param_idx_next-1) % nparam ) + 1
     param_active = collect(param_active_first:(param_active_first+num_param_active-1))
     for i in 1:length(param_active)
         if param_active[i] > nparam
            param_active[i] -= nparam
         end
     end 
     println("# Proposals to perturb parameters: ", param_active)
     make_proposal_dist_gaussian_cycle_subset_neighbors_param_idx_next += num_param_active
     if make_proposal_dist_gaussian_cycle_subset_neighbors_param_idx_next > nparam
        make_proposal_dist_gaussian_cycle_subset_neighbors_param_idx_next = make_proposal_dist_gaussian_cycle_subset_neighbors_cycle_start_idx_next
        make_proposal_dist_gaussian_cycle_subset_neighbors_cycle_start_idx_next = ( (make_proposal_dist_gaussian_cycle_subset_neighbors_cycle_start_idx_next) % nparam ) + 1
     end
  end
  make_proposal_dist_gaussian_subset_full_covar(pop,tau_factor, verbose=verbose, param_active=param_active )
end

function make_proposal_dist_gaussian_subset_zoomed_diag_covar(pop::abc_population_type, tau_factor::Float64; verbose::Bool = false, param_active::Vector{Int64} = collect(1:size(pop.covar,1)), inactive_scale_factor::Float64 = 0.25, max_maha_distsq_per_dim::Real = 4.0 )
  weights = pop.weights
  # weights = ones(pop.weights)./length(pop.weights) # pop.weights
  theta_mean =  sum(pop.theta.*weights',dims=2) # weighted mean for parameters
  tau = tau_factor*var_weighted(pop.theta'.-theta_mean',weights)  # scaled, weighted covar for parameters
  if verbose
    println("theta_mean = ", theta_mean)
    println("pop.theta = ", pop.theta)
    println("pop.weights = ", pop.weights)
    #println("weights = ", weights)
    println("tau = ", tau)
  end
  for i in 1:length(param_active)
    @assert 1<=param_active[i]<=length(tau)
    tau[param_active[i]] *= inactive_scale_factor
  end
  covar = PDiagMat(tau)
  max_maha_distsq = 4.0
  if max_maha_distsq_per_dim > 0
      max_maha_distsq = max_maha_distsq_per_dim*size(theta_mean,1)
      sampler = GaussianMixtureModelCommonCovarTruncated(pop.theta,pop.weights,covar,max_maha_distsq)
  else
     sampler = GaussianMixtureModelCommonCovar(pop.theta,pop.weights,covar)
  end
  return sampler
end

function make_proposal_dist_gaussian_cycle_zoomed_subset_neighbors_diag_covar(pop::abc_population_type, tau_factor::Float64; verbose::Bool = false, num_param_active::Integer = 2, inactive_scale_factor::Float64 = 0.25,  max_maha_distsq_per_dim::Real = 4.0 )
  global make_proposal_dist_gaussian_cycle_subset_neighbors_param_idx_next, make_proposal_dist_gaussian_cycle_subset_neighbors_cycle_start_idx_next
  nparam = size(pop.theta,1)
  if num_param_active == nparam
     param_active = 1:nparam
  else
     param_active_first = ( (make_proposal_dist_gaussian_cycle_subset_neighbors_param_idx_next-1) % nparam ) + 1
     param_active = collect(param_active_first:(param_active_first+num_param_active-1))
     for i in 1:length(param_active)
         if param_active[i] > nparam
            param_active[i] -= nparam
         end
     end
     println("# Proposals to perturb parameters: ", param_active)
     make_proposal_dist_gaussian_cycle_subset_neighbors_param_idx_next += num_param_active
     if make_proposal_dist_gaussian_cycle_subset_neighbors_param_idx_next > nparam
        make_proposal_dist_gaussian_cycle_subset_neighbors_param_idx_next = make_proposal_dist_gaussian_cycle_subset_neighbors_cycle_start_idx_next
        make_proposal_dist_gaussian_cycle_subset_neighbors_cycle_start_idx_next = ( (make_proposal_dist_gaussian_cycle_subset_neighbors_cycle_start_idx_next) % nparam ) + 1
     end
  end
  make_proposal_dist_gaussian_subset_zoomed_diag_covar(pop,tau_factor, verbose=verbose, param_active=param_active, inactive_scale_factor=inactive_scale_factor, max_maha_distsq_per_dim=max_maha_distsq_per_dim )
end


