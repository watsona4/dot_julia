# Generate an array of thetas (useful for custom parallelization)
function generate_thetas(plan::abc_pmc_plan_type, sampler::Distribution, ss_true, epsilon::Float64, num_to_generate::Integer; num_max_attempt = plan.num_max_attempt)
    @assert(epsilon>0.0)
    ex_sample = rand(sampler)
    num_param = length(ex_sample)
    thetas = Array(eltype(ex_sample),num_param,num_to_generate)
    dists = Array(Float64, num_to_generate)  # Warning should make aware of distance return type
    attempts = Array(Int64,  num_to_generate)
    for i in 1:num_to_generate
      thetas[:,i], dists[i], attempts[i] = generate_theta(plan, sampler, ss_true, epsilon, num_max_attempt = num_max_attempt )
    end
    return (thetas, dists, attempts)
end

# Generate initial abc population from prior, aiming for d(ss,ss_true)<epsilon
function init_abc_parallel_custom(plan::abc_pmc_plan_type, ss_true)   # WARNING PARALLEL CODE UNTESTED
  num_param = length(Distributions.rand(plan.prior))
  num_draw = plan.num_part
  nw = nworkers()

  job = Array(RemoteRef, nw)
  a = [1:ifloor(num_draw/nw):num_draw][1:nw]
  b = Array(Int64,nw)
  for i in 1:nw-1
     b[i] = a[i+1]-1
  end
  b[end] = num_draw

  for j in 1:nw
    #println("# Starting jobs ",j," with entries ", a[j], " to ", b[j])
    # Draw initial set of theta's from prior (either with dist<epsilon or best of num_max_attempts)
    job[j] = @spawn generate_thetas(plan, plan.prior, ss_true, plan.epsilon_init, b[j]-a[j]+1) 
  end

  # Allocate arrays for results on master
  theta = Array(Float64,(num_param,plan.num_part))
  dist_theta = Array(Float64, plan.num_part)
  attempts = Array(Int64, plan.num_part)
  # Retreive results
  for j in 1:nw
    theta[:,a[j]:b[j]], dist_theta[a[j]:b[j]], attempts[a[j]:b[j]] = fetch(job[j])
  end
  weights = fill(1.0/plan.num_part,plan.num_part)
  return abc_population_type(theta,weights,dist_theta)
end

