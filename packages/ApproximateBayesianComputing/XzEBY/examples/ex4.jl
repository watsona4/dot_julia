using ApproximateBayesianComputing
const ABC = ApproximateBayesianComputing
using Distributions
using PDMats
include(joinpath(Pkg.dir("ABC"),"src/composite.jl"))  # Not yet put in it's own package
using CompositeDistributions
import Compat.view # For backward compatability with v0.4

# Set HyperPrior for Population Parameters
param_prior_rate = Gamma(1.0,1.0)
 param_prior_mean  = MvLogNormal(log([10.0, 10.0]), diagm(log([10.0,10.0])))
 param_prior_covar_diag = MvLogNormal(zeros(2),ones(2))
 param_prior_cor = MvNormal(zeros(1),ones(1));
 param_prior = CompositeDist( ContinuousDistribution[param_prior_rate,param_prior_mean,param_prior_covar_diag,param_prior_cor] )
 num_star_default = 1000   # How many "stars" to include in universe

 function is_valid_mean_covar(theta::Array{Float64,1})  # Ensure that the proposed covariance matrix is positive definite
  a = theta[4]^2                     # WARNING: Covariance matrix extracted here and when generating data must match
  b = theta[4]*theta[5]*theta[6]
  c = theta[4]*theta[5]*theta[6]
  d = theta[5]^2
  tr_covar = a+d
  det_covar = a*d-b*c
  if (det_covar>0) && (tr_covar>0)
    return true
  else
    return false
  end
 end

function detection_prob_snr_term(snr::Real) # Detection probability as a function of signal-to-noise ratio
  const sig =  1.0
  const snr_thresh = 7.1
  const snr_detect_never =  3.0
  const snr_detect_always = 10.0
  const sqrt2 = sqrt(2.0)
  pdet = 0.0
  if snr > snr_detect_always
     pdet = 1.0
  elseif snr > snr_detect_never
     pdet = 0.5*( 1+erf((snr - snr_thresh)/(sqrt2*sig)) )
  end
  return pdet
 end

 function detection_prob_geometry_term(period::Real) # Transit probability as a function of orbital geometry
    const radius_star = 0.005
    const days_in_year = 365.2425
    a = (period/days_in_year)^(2//3)
    prob_geometric = min(1.0,radius_star/a)
 end

 detection_prob_return_one(period::Real, snr::Real) = 1.0
 detection_prob_snr_only(period::Real, snr::Real) = detection_prob_snr_term(snr)
 detection_prob_geometry_only(period::Real, snr::Real) = detection_prob_geometry_term(period)
 detection_prob_snr_and_geometry(period::Real, snr::Real) = detection_prob_geometry_term(period) * detection_prob_snr_term(snr)

 # Code to generate simulated data given array of model parameters
 function gen_number_planets(theta::Array, num_stars::Integer)
    #rate = theta[1]>0 ? sum(rand(Poisson(theta[1]),num_stars)) : 0
    rate = theta[1]^2
    sum(rand(Poisson(rate),num_stars))
 end
 function gen_period_snr(theta::Array, n::Integer)  # Just return "planet" properties
  mean = theta[2:3]
  covar = PDMat([theta[4]^2 theta[4]*theta[5]*theta[6]; theta[4]*theta[5]*theta[6] theta[5]^2])
  period_snr = rand(MvLogNormal(mean,covar),n)
  return period_snr
 end

 function gen_period_snr_detected(theta::Array, num_stars::Integer; detection_prob::Function = detection_prob_snr_and_geometry)  # "Planets" detection efficient depends on SNR and orbital period
  n = gen_number_planets(theta,num_stars)
  period_snr = gen_period_snr(theta,n)
  detected = trues(n)
  for i in 1:n
    period = period_snr[1,i]
    snr = period_snr[2,i]
    prob_detect = detection_prob( period, snr )
    if rand() > prob_detect
      detected[i] = false
    end
  end
  return (period_snr, detected)
 end

 gen_period_snr_detected_all(theta::Array, n::Integer = num_star_default) = gen_period_snr_detected(theta,n,detection_prob=detection_prob_return_one)
 gen_period_snr_detected_snr_only(theta::Array, n::Integer = num_star_default) = gen_period_snr_detected(theta,n,detection_prob=detection_prob_snr_only)
 gen_period_snr_detected_geometry_only(theta::Array, n::Integer = num_star_default) = gen_period_snr_detected(theta,n,detection_prob=detection_prob_geometry_only)
 gen_period_snr_detected_snr_and_geo(theta::Array, n::Integer = num_star_default) = gen_period_snr_detected(theta,n,detection_prob=detection_prob_snr_and_geometry)


function calc_summary_stats_mean_stddev_detected(data::Tuple{Array{Float64,2},BitArray{1}})
  period_snr = data[1]
  detected = data[2]
  @assert size(period_snr,1) == 2
  @assert size(period_snr,2) == length(detected)
  num_detected = length(find(detected))
  if num_detected<1
    return [0/num_star_default,Inf,Inf,Inf,Inf,Inf]
  end
  mean_log_period = mean(log(period_snr[1,detected]))
  mean_log_snr = mean(log(period_snr[2,detected]))
  if num_detected<2
     return [num_detected/num_star_default,mean_log_period,Inf,mean_log_snr,Inf,Inf]
  end
  stddev_log_period = stdm(log(period_snr[1,detected]),mean_log_period)
  stddev_log_snr = stdm(log(period_snr[2,detected]),mean_log_snr)
  covar_cross = sum( (log(period_snr[1,detected]).-mean_log_period) .* (log(period_snr[2,detected]).-mean_log_snr) )/(length(find(detected))-1)
  cor =  covar_cross / ( stddev_log_period*stddev_log_snr*(num_detected-1) )
  #cor_F = atanh(cor)*max(1,sqrt(num_detected-3))
  #c4 = calc_c4(num_detected)
  #stddev_coeff = sqrt((num_detected-1-c4*c4)/num_detected)
  return [num_detected/num_star_default, mean_log_period, stddev_log_period, mean_log_snr, stddev_log_snr, cor]
  #[ sqrt(num_detected)/num_star_default, stddev_log_period/sqrt(num_detected), stddev_coeff*stddev_log_period, stddev_log_snr/sqrt(num_detected), stddev_coeff*stddev_log_snr, 1.0 ]
end

function est_sigma_pred(x::Array{Float64,2},y::Array{Float64,1}) #,index::Integer)
  n = num_star_default*y[1]
  sd_logp = y[3]
  sd_logsnr = y[5]
  return [sqrt(n)/num_star_default, sd_logp/sqrt(n), sd_logp, sd_logsnr/sqrt(n), sd_logsnr, 1.0]
end


function calc_c4(n)
  sqrt(2//(n-1)) * (gamma(n//2)/gamma((n-1)//2))
end

theta_true = [1.0, log(10.0), log(10.0), log(10.0), log(10.0), 0.0] # True Population Parameters
#=
theta_true = fill(NaN,5) #  Generate from hyperprior
 while !is_valid_mean_covar(theta_true)
  theta_true = rand(param_prior)
 end
 theta_true
=#
# Uncomment one of three options below one to pick how data is generated
#gen_data = gen_period_snr_detected_all
#num_star_default = 2000   # How many "planets" to include in universe
gen_data = gen_period_snr_detected_snr_only
num_star_default = 4000   # How many "planets" to include in universe
#gen_data = gen_period_snr_detected_snr_and_geo
#num_star_default = 24000   # How many "planets" to include in universe

#=
ex_data =gen_data(theta_true)
calc_summary_stats_mean_stddev_detected(ex_data)
length(find(ex_data[2]))
=#

# Tell ABC what it needs to know for a simulation
abc_plan = abc_pmc_plan_type(gen_data,calc_summary_stats_mean_stddev_detected,ABC.calc_scaled_dist_max, param_prior;
                             is_valid=is_valid_mean_covar,adaptive_quantiles=true,num_max_attempt=1000,
                             target_epsilon=0.01,epsilon_init=10.0,num_part=50,
   make_proposal_dist = ABC.make_proposal_dist_gaussian_full_covar);

# Generate "true/observed data"
data_true = gen_data(theta_true)   # Draw "real" data from same model as for analysis
ss_true = abc_plan.calc_summary_stats(data_true)
ABC.set_distance_scale(abc_plan, theta_true, ss = ss_true )

#data_star =
#ss_star =
#dist_star = plan.calc_dist(ss_true,plan.calc_summary_stats(plan.gen_data(theta_star)))

#=
pdf(abc_plan.prior,theta_true)
CompositeDistributions.index(abc_plan.prior,1)
CompositeDistributions.index(abc_plan.prior,2)
logpdf(abc_plan.prior.dist[1],theta_true[CompositeDistributions.index(abc_plan.prior,1)])
logpdf(abc_plan.prior.dist[2],theta_true[CompositeDistributions.index(abc_plan.prior,2)])

logpdf(abc_plan.prior.dist[1],theta_true[1:2])
logpdf(abc_plan.prior.dist[2],theta_true[3:5])
println("***************************************************")
=#
# Run ABC simulation
@time pop_out = run_abc(abc_plan,ss_true, verbose=true);

using JLD
save("ex4_out.jld", "pop_out", pop_out)

using PyPlot
function plot_abc_posterior(theta_plot::Array{Float64,2}, index::Integer)
  lo = minimum(theta_plot[index,:])
  hi = maximum(theta_plot[index,:])
  sigma = 1.0*sqrt(abs(cov(vec(theta_plot[index,:]))))
  x = collect(linspace(lo-3*sigma,hi+3*sigma,100))
  y = zeros(x)
  for i in 1:length(x)
    for j in 1:size(theta_plot,2)
      y[i] += pdf(Normal(theta_plot[index,j],sigma),x[i])/size(theta_plot,2)
    end
  end
  plot(x,y,"-")
end

plot_abc_posterior(pop_out.theta,1)
plot_abc_posterior(pop_out.theta,2)
plot_abc_posterior(pop_out.theta,3)
plot_abc_posterior(pop_out.theta,4)
plot_abc_posterior(pop_out.theta,5)
plot_abc_posterior(pop_out.theta,6)

#=
sampler_plot = abc_plan.make_proposal_dist(pop_out, 1.0) # abc_plan.tau_factor)
num_plot = 100
epsilon = 0.05
theta_plot, dist_plot = generate_abc_sample(abc_plan,sampler_plot, ss_true, epsilon, n=num_plot )
plot_abc_posterior(theta_plot,1)
med_dist = median(dist_plot)
plot_abc_posterior(theta_plot[:,find(dist_plot.<=med_dist)],1)
=#

