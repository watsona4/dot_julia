
function push_to_abc_log!(abc_log::abc_log_type, plan::abc_pmc_plan_type, theta_star::Array{Float64,1}, ss_star, dist_star::Float64)
         if plan.save_params
           push!(abc_log.theta, theta_star)
         end
         if plan.save_summary_stats
           push!(abc_log.ss, ss_star)
         end
         if plan.save_distances
           push!(abc_log.dist, dist_star)
         end
end

function append_to_abc_log!(abc_log::abc_log_type, plan::abc_pmc_plan_type, theta_star::Array{Array{Float64,1},1}, ss_star::Array{Any,1}, dist_star::Array{Float64,1})
         if plan.save_params
           append!(abc_log.theta, theta_star)
         end
         if plan.save_summary_stats
           append!(abc_log.ss, ss_star)
         end
         if plan.save_distances
           append!(abc_log.dist, dist_star)
         end
end


function draw_indices(abc_log::ABC.abc_log_type, num_use::Integer, start_idx::Integer = 1, stop_idx::Integer = length(abc_log.dist))
  @assert num_use >=1
  num_available = 1+stop_idx-start_idx
  idx = collect(start_idx:min(start_idx+num_available-1,start_idx+num_use-1))
end

function draw_indicies_from_generations(accept_log::ABC.abc_log_type, reject_log::ABC.abc_log_type, generation_list::Vector{Int64}, num_use::Integer = 10)
 @assert length(generation_list) >= 1
 num_use_accepts = num_use
 num_use_rejects = num_use
 idx_accept = Int64[]
 idx_reject = Int64[]
 for generation in generation_list
    if (generation<1)||(generation>length(accept_log.generation_starts_at)) continue end
    @assert length(accept_log.generation_starts_at) == length(reject_log.generation_starts_at) >= generation >=1
    stop_idx_accept = generation+1 <= length(accept_log.generation_starts_at) ? accept_log.generation_starts_at[generation+1] : length(accept_log.dist)
    stop_idx_reject = generation+1 <= length(reject_log.generation_starts_at) ? reject_log.generation_starts_at[generation+1] : length(reject_log.dist)
    idx_accept_this_gen = draw_indices(accept_log,num_use_accepts,accept_log.generation_starts_at[generation],stop_idx_accept)
    num_use_rejects_adjusted = num_use_rejects + num_use_accepts - length(idx_accept_this_gen)
    idx_reject_this_gen = draw_indices(reject_log,num_use_rejects_adjusted,reject_log.generation_starts_at[generation],stop_idx_reject)
    append!(idx_accept,idx_accept_this_gen)
    append!(idx_reject,idx_reject_this_gen)
 end
 return (idx_accept,idx_reject)
end

function make_training_data(accept_log::ABC.abc_log_type, reject_log::ABC.abc_log_type, generation_list::Vector{Int64}, num_use::Integer = 10)
 @assert length(accept_log.theta) == length(accept_log.ss) == length(accept_log.dist) >= 1
 @assert length(reject_log.theta) == length(reject_log.ss) == length(reject_log.dist) >= 1
 @assert length(accept_log.theta[1]) >=1
 @assert length(reject_log.theta[1]) >=1
 @assert length(accept_log.ss[1]) == length(reject_log.ss[1])
 (idx_accept,idx_reject) = draw_indicies_from_generations(accept_log,reject_log,generation_list,num_use)

 num_use_total = length(idx_accept) + length(idx_reject)
 num_param = length(accept_log.theta[1])
 num_ss = length(accept_log.ss[1])
 x_train = Array{Float64}(num_param,num_use_total)
 y_train = Array{Float64}(num_ss,num_use_total)
 println("# idx_accept = ",idx_accept)
 println("# size(x_train)",size(x_train))
 println("# size(accept_log.theta[idx_accept]) = ", size( accept_log.theta[idx_accept]))
 for i in 1:length(idx_accept)
    x_train[:,i] = accept_log.theta[idx_accept[i]]
    y_train[:,i] = accept_log.ss[idx_accept[i]]
 end
 for i in 1:length(idx_reject)
    x_train[:,length(idx_accept)+i] = reject_log.theta[idx_reject[i]]
    y_train[:,length(idx_accept)+i] = reject_log.ss[idx_reject[i]]
 end
 return (x_train, y_train)
end

###=
function test_emu(pop_out::abc_population_type, theta::Array{Float64,1}, num_use::Integer = 100)
num_use = 100
(x_train,y_train) = ABC.make_training_data(pop_out.accept_log, pop_out.reject_log, [length(pop_out.accept_log.generation_starts_at)], num_use)
 sample_var_y_train = var(y_train,2)
 sigmasq_y_train = similar(y_train)
 for i in 1:size(y_train,2)
   sigmasq_y_train[:,i] = sample_var_y_train
 end
 emu = ABC.train_gp(x_train,y_train,sigmasq_y_train)
 function emulate_ss(theta::Array{Float64,2})
   predict_gp(emu,theta)
 end
 function emulate_ss(theta::Array{Float64,1})
   predict_gp(emu,reshape(theta,size(theta,1),1))
 end

 function emulator_output_to_ss_mean_stddev( emu_output::Tuple{Array{Float64,2},Array{Float64,3}} )
   m = emu_output[1]
   stddev = similar(emu_output[1])
   for i in 1:size(emu_output[1],1)
     stddev[i,:] = diag(emu_output[2][1,:,:])
   end
   return (m,stddev)
 end

  emu_out = emulate_ss(theta)
  ss_mean_stddev = emulator_output_to_ss_mean_stddev(emu_out)
  return (vec(ss_mean_stddev[1]),vec(ss_mean_stddev[2]))
end

function emu_accept_prob(ss_true::Array{Float64,1},emu_out::Tuple{Array{Float64,1},Array{Float64,1}}, epsilon::Real)
  mu = emu_out[1]
  sig = emu_out[2]
  prob_accept = 1.0
  for i in 1:length(ss_true)
    cdf_hi = cdf(Normal(mu[i],sig[i]),ss_true[i]+epsilon)
    cdf_lo = cdf(Normal(mu[i],sig[i]),ss_true[i]-epsilon)
    prob_accept *= cdf_hi-cdf_lo
  end
  return prob_accept
end

function emu_accept_reject_run_full_model(ss_true::Array{Float64,1},emu_out::Tuple{Array{Float64,1},Array{Float64,1}}, epsilon::Real; prob_accept_crit::Real = 0.999, prob_reject_crit::Real = 0.001)
  prob_accept = emu_accept_prob(ss_true,emu_out,epsilon)
  if prob_accept > prob_accept_crit
    return 1
  elseif  prob_accept < prob_reject_crit
    return -1
  else
    return 0
  end
end

#=
x = collect(linspace(0.0,0.1,200))
y=  map(x->emu_accept_reject(ss_true,emu_out,x),x)
plot(x,y)
=#
