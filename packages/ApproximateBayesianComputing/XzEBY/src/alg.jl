#using JLD

function generate_theta(plan::abc_pmc_plan_type, sampler::Distribution, ss_true, epsilon::Float64; num_max_attempt = plan.num_max_attempt)
      @assert(epsilon>=0.0)
      dist_best = Inf
      local theta_best
      #summary_stats_log = abc_log_type()
      #push!(summary_stats_log.generation_starts_at, 1)
      accept_log = abc_log_type()
      reject_log = abc_log_type()
      push!(accept_log.generation_starts_at, 1)
      push!(reject_log.generation_starts_at, 1)
      attempts = 0
      all_attempts = num_max_attempt
      for a in 1:num_max_attempt
         theta_star = rand(sampler)
         if (typeof(theta_star) <: Real)   # in case return a scalar, make into array
            theta_star = fill(theta_star, length(plan.prior))  ### TODO: Univariate uniform prior returns length 1 -> need to generalize for multiple bins.
            #theta_star = [theta_star]
         end
         plan.normalize(theta_star)
         if(!plan.is_valid(theta_star)) continue end
         attempts += 1
         data_star = plan.gen_data(theta_star)
         ss_star = plan.calc_summary_stats(data_star)

         accept_prob = 0.
         local dist_star
         for d in 1:plan.num_dist_per_obs
           dist_star = plan.calc_dist(ss_true,ss_star)
         #=
         if plan.save_params
           push!(summary_stats_log.theta, theta_star)
         end
         if plan.save_summary_stats
           push!(summary_stats_log.ss, ss_star)
         end
         if plan.save_distances
           push!(summary_stats_log.dist, dist_star)
         end
         =#
           if dist_star < dist_best
              dist_best = dist_star
              theta_best = copy(theta_star)
           end
           if(dist_star < epsilon)
             accept_prob += 1.0
           end
         end
         accept_prob /= plan.num_dist_per_obs 

         accept = rand() < accept_prob

         if(!accept)
              push_to_abc_log!(reject_log,plan,theta_star,ss_star,dist_star)
         else
              push_to_abc_log!(accept_log,plan,theta_star,ss_star,dist_star)
              all_attempts = a
              break
         end
      end
      if dist_best == Inf
        error("# Failed to generate any acceptable thetas.")
      end
      # println("gen_theta: d= ",dist_best, " num_valid_attempts= ",attempts, " num_all_attempts= ", all_attempts, " theta= ", theta_best)
      #return (theta_best, dist_best, attempts, summary_stats_log)
      return (theta_best, dist_best, attempts, accept_log, reject_log)
end

function generate_abc_sample(plan::abc_pmc_plan_type, sampler::Distribution, ss_true, epsilon::Real; n::Integer = 100)
  if in_parallel
   nw = nworkers()
   @assert (nw > 1)
   return generate_abc_sample_distributed_map(plan,ss_true)
  else
   return generate_abc_sample_serial(plan,ss_true)
  end
end

# Generate initial abc population from prior, aiming for d(ss,ss_true)<epsilon
function init_abc(plan::abc_pmc_plan_type, ss_true; in_parallel::Bool = plan.in_parallel)
  if in_parallel
    nw = nworkers()
    @assert (nw > 1)
    #@assert (plan.num_part > 2*nw)  # Not really required, but seems more likely to be a mistake
    #return init_abc_parallel_map(plan,ss_true)
    return init_abc_distributed_map(plan,ss_true)
  else
    return init_abc_serial(plan,ss_true)
  end
end


# run the ABC algorithm matching to summary statistics ss_true, starting from an initial population (e.g., output of previous call)
function run_abc(plan::abc_pmc_plan_type, ss_true, pop::abc_population_type; verbose::Bool = false, print_every::Integer=1, in_parallel::Bool = plan.in_parallel )
  attempts = zeros(Int64,plan.num_part)
  # Set initial epsilon tolerance based on current population
  epsilon = quantile(pop.dist,plan.init_epsilon_quantile)
  eps_diff_count = 0

  # Uncomment for generation info output to log file
  #  
  if verbose
     f_log = open("generation_log.txt", "w")
  end
  #

  # Uncomment for history output at end of run to terminal
  #
  eps_arr = []
  mean_arr = []
  std_arr = []  
  #

  for t in 1:plan.num_max_times
    local new_pop
    sampler = plan.make_proposal_dist(pop, plan.tau_factor)
    if plan.adaptive_quantiles
      min_quantile = t==1 ? 4.0/size(pop.theta,2) : 1.0/sqrt(size(pop.theta,2))
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
       println("# t= ",t, " eps= ",epsilon, " med(d)= ",median(pop.dist), " attempts= ",median(attempts), " ",maximum(attempts), " reps= ", sum(pop.repeats), " ess= ",ess(pop.weights,pop.repeats)) #," mean(theta)= ",mean(pop.theta,dims=2) )#) #, " tau= ",diag(tau) ) #
       println("Mean(theta)= ", mean(pop.theta, dims=2), " Stand. Dev.(theta)= ", std(pop.theta, dims=2))

       # Uncomment for generation info output to log file
       #
       println(f_log, "# t= ",t, " eps= ",epsilon, " med(d)= ",median(pop.dist), " attempts= ",median(attempts), " ",maximum(attempts), " reps= ", sum(pop.repeats), " ess= ",ess(pop.weights,pop.repeats))
       println(f_log, "Mean(theta)= ", mean(pop.theta, dims=2), " Stand. Dev.(theta)= ", std(pop.theta, dims=2))
       flush(f_log)
       #save(string("gen-",t,".jld"), "pop_out", pop, "ss_true", ss_true)
       #
        
    end
    # Uncomment for history output at end of run to terminal
    #
    push!(eps_arr, epsilon)
    push!(mean_arr, mean(pop.theta,dims=2)[1])
    push!(std_arr, std(pop.theta,dims=2)[1])
    #
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
      println("# Halting due to ", sum(pop.repeats), " repeats.")
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
      println("# Halting due to epsilon goal remaining the same for 3 consecutive generations.")
      break
    end  end # t / num_times
    #println("mean(theta) = ",[ sum(pop.theta[i,:])/size(pop.theta,2) for i in 1:size(pop.theta,1) ])

  # Uncomment for history output at end of run to terminal
  #
  if verbose
     println("Epsilon history = ", eps_arr)
     println("Mean history = ", mean_arr)
     println("Std Dev. history = ", std_arr)
  end
  #

  # Uncomment for generation info output to log file
  #
  if verbose
     close(f_log)
  end
  #
  
  return pop
end

# run the ABC algorithm matching to summary statistics ss_true
function run_abc(plan::abc_pmc_plan_type, ss_true; verbose::Bool = false, print_every::Integer=1, in_parallel::Bool =  plan.in_parallel )                         # Initialize population, drawing from prior
  pop::abc_population_type = init_abc(plan,ss_true, in_parallel=in_parallel)
  #println("pop_init: ",pop)
  run_abc(plan, ss_true, pop; verbose=verbose, print_every=print_every, in_parallel=in_parallel )
end

function choose_epsilon_adaptive(pop::abc_population_type, sampler::Distribution; min_quantile::Real = 1.0/sqrt(size(pop.theta,2)) )
  sampler_logpdf = logpdf(sampler, pop.theta)
  target_quantile_this_itteration = min(1.0, exp(-maximum(sampler_logpdf .- pop.logpdf)) )
  if target_quantile_this_itteration > 1.0
     target_quantile_this_itteration = 1.0
  end
  optimal_target_quantile = target_quantile_this_itteration
  if target_quantile_this_itteration < min_quantile
     target_quantile_this_itteration = min_quantile
  end
  epsilon = quantile(pop.dist,target_quantile_this_itteration)
  println("# Estimated target quantile is ", optimal_target_quantile, " using ",target_quantile_this_itteration, " resulting in epsilon = ", epsilon)
  return epsilon
end


