using DistributedArrays

function generate_theta_return_theta_dist_only(plan::abc_pmc_plan_type, sampler::Distribution, ss_true, epsilon::Float64; num_max_attempt = plan.num_max_attempt, num_max_attempt_valid = plan.num_max_attempt_valid )
   ret = generate_theta_return_theta_dist_only(plan,sampler,ss_true,epsilon,num_max_attempt=num_max_attempt, num_max_attemp_valid=num_max_attempt_valid)
   return (ret[1],ret[2])
end

function generate_abc_sample_distributed_map(plan::abc_pmc_plan_type, sampler::Distribution, ss_true, epsilon::Real; n::Integer = 100)
  #num_param = length(Distributions.rand(plan.prior))
  num_param = length(plan.prior)
  output_dist = map(x->generate_theta_return_theta_dist_only(plan,sampler,ss_true,epsilon, n=n),dfill(nothing,n))
  output_local = convert(Array{Tuple{Array{Float64,1},Float64}},output_dist)

  theta_plot = Array(Float64,num_param,n)
  dist_plot = Array(Float64,n)
  for i in 1:n
     # theta_plot[:,i], dist_plot[i], attempts_plot, accept_log_plot, reject_log_plot = ABC.generate_theta(abc_plan, sampler, ss_true, epsilon)
     theta_plot[:,i] = output_local[i][1]
     dist_plot[i] = output_local[i][2]
  end  
  return theta_plot, dist_plot
end

function init_abc_distributed_map(plan::abc_pmc_plan_type, ss_true)
  #num_param = length(Distributions.rand(plan.prior))
  num_param = length(plan.prior)
  theta = Array(Float64,(num_param,plan.num_part))
  dist_theta = Array(Float64,plan.num_part)
  attempts = Array(Int64,plan.num_part)
  accept_log_combo = abc_log_type()
  reject_log_combo = abc_log_type()
  # Draw initial set of theta's from prior (either with dist<epsilon or best subject to num_max_attempts and num_max_valid_attempts)

  if plan.save_params || plan.save_summary_stats || plan.save_distances
     push!(accept_log_combo.generation_starts_at,length(accept_log_combo.dist)+1)
     push!(reject_log_combo.generation_starts_at,length(reject_log_combo.dist)+1)
  end

  map_results = map(x->generate_theta(plan, plan.prior, ss_true, plan.epsilon_init), dfill(nothing,plan.num_part) )
  @assert( length(map_results) == plan.num_part)
  #@assert( length(map_results[1]) >= 1)
  #num_param = length(map_results[1][1])
  for i in 1:plan.num_part
      generate_theta_result = map_results[i]
      theta[:,i] = generate_theta_result[1]
      dist_theta[i] = generate_theta_result[2]
      attempts[i] = generate_theta_result[3]
      accept_log = generate_theta_result[4]
      reject_log = generate_theta_result[5]
      append_to_abc_log!(accept_log_combo,plan,accept_log.theta,accept_log.ss,accept_log.dist)
      append_to_abc_log!(reject_log_combo,plan,reject_log.theta,reject_log.ss,reject_log.dist)
  end

  weights = fill(1.0/plan.num_part,plan.num_part)
  logpriorvals = Distributions.logpdf(plan.prior,theta)
  push!(accept_log_combo.epsilon,plan.epsilon_init)
  push!(reject_log_combo.epsilon,plan.epsilon_init)

  return abc_population_type(theta,weights,dist_theta,maximum(dist_theta),logpriorvals,accept_log_combo,reject_log_combo)
end


function update_abc_pop_parallel_distributed_map(plan::abc_pmc_plan_type, ss_true, pop::abc_population_type, sampler::Distribution, epsilon::Float64;
                        attempts::Array{Int64,1} = zeros(Int64,plan.num_part))
  #new_pop = deepcopy(pop)
  new_pop = abc_population_type(size(pop.theta,1), size(pop.theta,2), accept_log=pop.accept_log, reject_log=pop.reject_log, repeats=pop.repeats)
  if plan.save_params || plan.save_summary_stats || plan.save_distances
     push!(new_pop.accept_log.generation_starts_at,length(new_pop.accept_log.dist)+1)
     push!(new_pop.reject_log.generation_starts_at,length(new_pop.reject_log.dist)+1)
  end
  median_logpdf_old = median(pop.logpdf)
  dmap_results = map(x->generate_theta(plan, sampler, ss_true, epsilon), dfill(nothing,plan.num_part))
  #map_results = collect(dmap_results)
  for i in 1:plan.num_part
       #theta_star, dist_theta_star, attempts[i] = generate_theta(plan, sampler, ss_true, epsilon)
       # if dist_theta_star < pop.dist[i] # replace theta with new set of parameters and update weight
       theta_star = dmap_results[i][1]
       dist_theta_star =  dmap_results[i][2]
       attempts[i] = dmap_results[i][3]
       accept_log = dmap_results[i][4]
       reject_log = dmap_results[i][5]
       append_to_abc_log!(new_pop.accept_log,plan,accept_log.theta,accept_log.ss,accept_log.dist)
       append_to_abc_log!(new_pop.reject_log,plan,reject_log.theta,reject_log.ss,reject_log.dist)

       # if dist_theta_star < epsilon # replace theta with new set of parameters and update weight
         @inbounds new_pop.dist[i] = dist_theta_star
         @inbounds new_pop.theta[:,i] = theta_star
         prior_logpdf = Distributions.pdf(plan.prior,theta_star)
         if isa(prior_logpdf, Array)
            prior_logpdf = prior_logpdf[1]
         end
         # sampler_pdf calculation must match distribution used to update particle
         sampler_logpdf = logpdf(sampler, theta_star )
         @inbounds new_pop.weights[i] = exp(prior_logpdf-sampler_logpdf)
       if dist_theta_star < epsilon # replace theta with new set of parameters and update weight
         @inbounds new_pop.repeats[i] = 0
       else  # failed to generate a closer set of parameters, so...
         # ... generate new data set with existing parameters
         #new_data = plan.gen_data(theta_star)
         #new_ss = plan.calc_summary_stats(new_data)
         #@inbounds new_pop.dist[i] = plan.calc_dist(ss_true,new_ss)
         # ... just keep last value for this time, and mark it as a repeat
         @inbounds new_pop.theta[:,i] = pop.theta[:,i]
         @inbounds new_pop.dist[i] = pop.dist[i]
         @inbounds new_pop.weights[i] = pop.weights[i]
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
function init_abc_parallel_map(plan::abc_pmc_plan_type, ss_true)
  #num_param = length(Distributions.rand(plan.prior))
  pmap_results = pmap(x->generate_theta(plan, plan.prior, ss_true, plan.epsilon_init), collect(1:plan.num_part) )
  @assert( length(pmap_results) >= 1)
  @assert( length(pmap_results[1]) >= 1)
  num_param = length(pmap_results[1][1])
  theta = Array(Float64,(num_param,plan.num_part))
  dist_theta = Array(Float64,plan.num_part)
  attempts = Array(Int64,plan.num_part)
  #summary_stat_logs = Array(abc_log_type,plan.num_part)
  #summary_stat_log_combo = abc_log_type()
  accept_log_combo = abc_log_type()
  reject_log_combo = abc_log_type()
  if plan.save_params || plan.save_summary_stats || plan.save_distances
     push!(summary_stat_log_combo.generation_starts_at,length(summary_stat_log_combo.dist)+1)
  end
  for i in 1:plan.num_part
      theta[:,i]  = pmap_results[i][1]
      dist_theta[i]  = pmap_results[i][2]
      attempts[i]  = pmap_results[i][3]
      #=if plan.save_summary_stats
         summary_stat_logs[i] = pmap_results[i][4]
         append!(summary_stat_log_combo.theta, summary_stat_logs[i].theta)
         append!(summary_stat_log_combo.ss, summary_stat_logs[i].ss)
      end
      =#
         accept_log = pmap_results[i][4]
         reject_log = pmap_results[i][5]
         append_to_abc_log!(accept_log_combo,plan,accept_log.theta,accept_log.ss,accept_log.dist)
         append_to_abc_log!(reject_log_combo,plan,reject_log.theta,reject_log.ss,reject_log.dist)
      #=
      if plan.save_params || plan.save_summary_stats || plan.save_distances
         summary_stat_logs[i] = pmap_results[i][4]
         if plan.save_params
           append!(summary_stat_log_combo.theta, summary_stat_logs[i].theta)
        end
        if plan.save_summary_stats
          append!(summary_stat_log_combo.ss, summary_stat_logs[i].ss)
        end
        if plan.save_distances
           append!(summary_stat_log_combo.dist, summary_stat_logs[i].dist)
        end
      end
      =#
  end

  weights = fill(1.0/plan.num_part,plan.num_part)
  logpriorvals = Distributions.logpdf(plan.prior,theta)
  #return abc_population_type(theta,weights,dist_theta,plan.epsilon_init,logpriorvals,summary_stat_log_combo)
  return abc_population_type(theta,weights,dist_theta,plan.epsilon_init,logpriorvals,accept_log_combo,reject_log_combo)
end

# Update the abc population once
function update_abc_pop_parallel_pmap(plan::abc_pmc_plan_type, ss_true, pop::abc_population_type, sampler::Distribution, epsilon::Float64;
                        attempts::Array{Int64,1} = zeros(Int64,plan.num_part))
  #new_pop = deepcopy(pop)
  new_pop = abc_population_type(size(pop.theta,1), size(pop.theta,2), accept_log=pop.accept_log, reject_log=pop.reject_log, repeats=pop.repeats)
  pmap_results = pmap(x->generate_theta(plan, sampler, ss_true, epsilon), collect(1:plan.num_part))
  if plan.save_params || plan.save_summary_stats || plan.save_distances
     push!(new_pop.accept_log.generation_starts_at,length(new_pop.accept_log.dist)+1)
     push!(new_pop.reject_log.generation_starts_at,length(new_pop.reject_log.dist)+1)
  end
     for i in 1:plan.num_part
       #theta_star, dist_theta_star, attempts[i] = generate_theta(plan, sampler, ss_true, epsilon)
       # if dist_theta_star < pop.dist[i] # replace theta with new set of parameters and update weight
       theta_star = pmap_results[i][1]
       dist_theta_star =  pmap_results[i][2]
       accept_log = pmap_results[i][4]
       reject_log = pmap_results[i][5]
       append_to_abc_log!(new_pop.accept_log,plan,accept_log.theta,accept_log.ss,accept_log.dist)
       append_to_abc_log!(new_pop.reject_log,plan,reject_log.theta,reject_log.ss,reject_log.dist)

       #=
       if plan.params
          append!(new_pop.log.theta, pmap_results[i][4].theta)
       end
       if plan.save_summary_stats
          append!(new_pop.log.ss, pmap_results[i][4].ss)
       end
       if plan.save_distances
          append!(new_pop.log.dist, pmap_results[i][4].dist)
       end
       =#
       if dist_theta_star < epsilon # replace theta with new set of parameters and update weight
         @inbounds new_pop.theta[:,i] = theta_star
         @inbounds new_pop.dist[i] = dist_theta_star
         prior_logpdf = Distributions.logpdf(plan.prior,theta_star)
         if isa(prior_pdf, Array)
            prior_logpdf = prior_logpdf[1]
         end
         # sampler_pdf calculation must match distribution used to update particle
         sampler_logpdf = pdf(sampler, theta_star )
         @inbounds new_pop.weights[i] = exp(prior_logpdf-sampler_logpdf)
         @inbounds new_pop.repeats[i] = 0
       else  # failed to generate a closer set of parameters, so...
         # ... generate new data set with existing parameters
         #new_data = plan.gen_data(theta_star)
         #new_ss = plan.calc_summary_stats(new_data)
         #@inbounds new_pop.dist[i] = plan.calc_dist(ss_true,new_ss)
         # ... just keep last value for this time, and mark it as a repeat
         @inbounds new_pop.theta[:,i] = pop.theta[:,i]
         @inbounds new_pop.dist[i] = pop.dist[i]
         @inbounds new_pop.weights[i] = pop.weights[i]
         @inbounds new_pop.repeats[i] += 1
       end
     end # i / num_parts
   new_pop.weights ./= sum(new_pop.weights)
   return new_pop
end

=#