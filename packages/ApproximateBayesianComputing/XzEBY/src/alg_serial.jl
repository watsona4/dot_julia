function generate_abc_sample_serial(plan::abc_pmc_plan_type, sampler::Distribution, ss_true, epsilon::Real; n::Integer = 100)
  #num_param = length(Distributions.rand(plan.prior))
  num_param = length(plan.prior)
  theta_plot = Array{Float64}(undef,num_param, n)
  dist_plot = Array{Float64}(undef,n)
  for i in 1:n
    theta_plot[:,i], dist_plot[i], attempts_plot, accept_log_plot, reject_log_plot = ABC.generate_theta(abc_plan, sampler, ss_true, epsilon)
  end
  return theta_plot, dist_plot
end

# Generate initial abc population from prior, aiming for d(ss,ss_true)<epsilon
function init_abc_serial(plan::abc_pmc_plan_type, ss_true)
  num_param = length(Distributions.rand(plan.prior))
  # Allocate arrays
  theta = Array{Float64}(undef,num_param,plan.num_part)
  dist_theta = Array{Float64}(undef,plan.num_part)
  attempts = zeros(plan.num_part)
  accept_log_combo = abc_log_type()
  reject_log_combo = abc_log_type()
  # Draw initial set of theta's from prior (either with dist<epsilon or best subject to num_max_attempts and num_max_valid_attempts)

  if plan.save_params || plan.save_summary_stats || plan.save_distances
     push!(accept_log_combo.generation_starts_at,length(accept_log_combo.dist)+1)
     push!(reject_log_combo.generation_starts_at,length(reject_log_combo.dist)+1)
  end
  for i in 1:plan.num_part
      theta[:,i], dist_theta[i], attempts[i], accept_log, reject_log = generate_theta(plan, plan.prior, ss_true, plan.epsilon_init)
      append_to_abc_log!(accept_log_combo,plan,accept_log.theta,accept_log.ss,accept_log.dist)
      append_to_abc_log!(reject_log_combo,plan,reject_log.theta,reject_log.ss,reject_log.dist)
  end
  weights = fill(1.0/plan.num_part,plan.num_part)
  logpriorvals = Distributions.logpdf(plan.prior,theta)
  push!(accept_log_combo.epsilon,plan.epsilon_init)
  push!(reject_log_combo.epsilon,plan.epsilon_init)

  return abc_population_type(theta,weights,dist_theta,maximum(dist_theta),logpriorvals,accept_log_combo,reject_log_combo)
end

# Update the abc population once
function update_abc_pop_serial(plan::abc_pmc_plan_type, ss_true, pop::abc_population_type, sampler::Distribution, epsilon::Float64;
                        attempts::Array{Int64,1} = zeros(Int64,plan.num_part) )
  #new_pop = deepcopy(pop)
  new_pop = abc_population_type(size(pop.theta,1), size(pop.theta,2), accept_log=pop.accept_log, reject_log=pop.reject_log, repeats=pop.repeats)
  if plan.save_params || plan.save_summary_stats || plan.save_distances
     push!(new_pop.accept_log.generation_starts_at,length(new_pop.accept_log.dist)+1)
     push!(new_pop.reject_log.generation_starts_at,length(new_pop.reject_log.dist)+1)
  end
  median_logpdf_old = median(pop.logpdf)
     for i in 1:plan.num_part
       theta_star, dist_theta_star, attempts[i], accept_log, reject_log = generate_theta(plan, sampler, ss_true, epsilon)
       append_to_abc_log!(new_pop.accept_log,plan,accept_log.theta,accept_log.ss,accept_log.dist)
       append_to_abc_log!(new_pop.reject_log,plan,reject_log.theta,reject_log.ss,reject_log.dist)

       #if dist_theta_star < epsilon # replace theta with new set of parameters and update weight
         @inbounds new_pop.dist[i] = dist_theta_star
         @inbounds new_pop.theta[:,i] = theta_star
         prior_logpdf = Distributions.logpdf(plan.prior,theta_star)
         #if isa(prior_logpdf, Array)   # TODO: Can remove this once Danley's code uses composite distribution
         #   prior_logpdf = prior_logpdf[1]
         #end
         # sampler_pdf calculation must match distribution used to update particle
         sampler_logpdf = logpdf(sampler, theta_star )
         #@inbounds new_pop.weights[i] = prior_pdf/sampler_pdf
         @inbounds new_pop.weights[i] = exp(prior_logpdf-sampler_logpdf)
         @inbounds new_pop.logpdf[i] = sampler_logpdf
      if dist_theta_star < epsilon # replace theta with new set of parameters and update weight
         @inbounds new_pop.repeats[i] = 0
       else  # failed to generate a closer set of parameters, so...
         # ... generate new data set with existing parameters
         #new_data = plan.gen_data(theta_star)
         #new_ss = plan.calc_summary_stats(new_data)
         #@inbounds new_pop.dist[i] = plan.calc_dist(ss_true,new_ss)
         # ... just keep last value for this time, and mark it as a repeat
         #=
         @inbounds new_pop.dist[i] = pop.dist[i]
         @inbounds new_pop.theta[:,i] = pop.theta[:,i]
         @inbounds new_pop.weights[i] = pop.weights[i]
         @inbounds new_pop.logpdf[i] = pop.logpdf[i]
         =#
         @inbounds new_pop.repeats[i] += 1
       end
     end # i / num_parts
   new_pop.weights ./= sum(new_pop.weights)
   push!(new_pop.accept_log.epsilon,epsilon)
   push!(new_pop.reject_log.epsilon,epsilon)
   #println("New pop weights = ", new_pop.weights)
   return new_pop
end

#=
# run the ABC algorithm matching to summary statistics ss_true, starting from an initial population (e.g., output of previosu call)
function run_abc(plan::abc_pmc_plan_type, ss_true, pop::abc_population_type; verbose::Bool = false, print_every::Integer=1, in_parallel::Bool = plan.in_parallel )
  attempts = zeros(Int64,plan.num_part)
  # Set initial epsilon tolerance based on current population
  epsilon = quantile(pop.dist,plan.init_epsilon_quantile)
  eps_diff_count = 0
  for t in 1:plan.num_max_times
    local new_pop
    sampler = plan.make_proposal_dist(pop, plan.tau_factor)
    if plan.adaptive_quantiles
      min_quantile = t==1 ? 4.0/size(pop.theta,2) : 0.5 # 1.0/sqrt(size(pop.theta,2))
      epsilon = choose_epsilon_adaptive(pop, sampler, min_quantile=min_quantile)
    end
    if in_parallel
      #new_pop = update_abc_pop_parallel_darray(plan, ss_true, pop, epsilon, attempts=attempts)
       new_pop = update_abc_pop_parallel_distributed_map(plan, ss_true, pop, sampler, epsilon, attempts=attempts)
    else
	  #new_pop = update_abc_pop_serial(plan, ss_true, pop, epsilon, attempts=attempts)
      new_pop = update_abc_pop_serial(plan, ss_true, pop, sampler, epsilon, attempts=attempts)
    end
    pop = new_pop
    if verbose && (t%print_every == 0)
       println("# t= ",t, " eps= ",epsilon, " med(d)= ",median(pop.dist), " attempts= ",median(attempts), " ",maximum(attempts), " reps= ", sum(pop.repeats), " ess= ",ess(pop.weights)) #," mean(theta)= ",mean(pop.theta,2) )#) #, " tau= ",diag(tau) ) #
       # println("# t= ",t, " eps= ",epsilon, " med(d)= ",median(pop.dist), " max(d)= ", maximum(pop.dist), " med(attempts)= ",median(attempts), " max(a)= ",maximum(attempts), " reps= ", sum(pop.repeats), " ess= ",ess(pop.weights,pop.repeats)) #," mean(theta)= ",mean(pop.theta,2) )#) #, " tau= ",diag(tau) ) #
       println("# Mean(theta)= ", mean(pop.theta, 2), " Stand. Dev.(theta)= ", std(pop.theta, 2))
    end
    #if epsilon < plan.target_epsilon  # stop once acheive goal
    if maximum(pop.dist) < plan.target_epsilon  # stop once acheive goal
       println("# Reached ",epsilon," after ", t, " generations.")
       break
    end
    if median(attempts)>0.2*plan.num_max_attempt
      println("# Halting due to ", median(attempts), " median number of valid attempts.")
      break
    end
    if sum(pop.repeats)>plan.num_part
      println("# Halting due to ", sum(pop.repeats), " repeats. (Due to change, this is poor word choice. Really, it's too many failed attempts to generate parameters resulting in distance less than epsilon.)")
      break
    end
    eps_old = epsilon
    if maximum(attempts)<0.75*plan.num_max_attempt
      epsilon = minimum([maximum(pop.dist),epsilon * plan.epsilon_reduction_factor])
    end
    if ((abs(eps_old-epsilon)/epsilon) < 1.0e-5)
      eps_diff_count += 1
    else
      eps_diff_count = 0
    end
    if eps_diff_count > 1
      println("# Halting due to epsilon not improving significantly for 3 consecutive generations.")
      break
    end
  end # t / num_times
 #println("mean(theta) = ",[ sum(pop.theta[i,:])/size(pop.theta,2) for i in 1:size(pop.theta,1) ])
  if verbose 
     println("# Epsilon history = ", pop.accept_log.epsilon)
     #println("Epsilon history = ", eps_arr)
     #println("Mean history = ", mean_arr)
     #println("Std Dev. history = ", std_arr)
  end
  return pop
end
=#


