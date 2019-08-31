# If want to use an empty function for normalizing/testing validity of parameters
noop(x::Array) = return true
noop(x::Real) = return true

# Copy population
import Base.copy
copy(x::abc_population_type) = abc_population_type(copy(x.theta),copy(x.weights),copy(x.dist), x.epsilon, copy(x.repeats))

# Compute weighted covariance of sample (from origin)
function cov_weighted(x::Array{Float64,2}, w::Array{Float64,1} )
  @assert(size(x,1)==length(w) )
  sumw = sum(w)
  @assert( sumw > 0. )
  if(sumw!= 1.0)
     w /= sum(w)
     sumw = 1.0
  end
  sumw2 = sum(w.*w)
  xbar = [ sum(x[:,i].*w) for i in 1:size(x,2) ]
  covar = zeros(size(x,2),size(x,2))
  for k in 1:size(x,2)
    for j in 1:size(x,2)
        for i in 1:size(x,1)
            @inbounds covar[j,k] += (x[i,j]-xbar[j])*(x[i,k]-xbar[k]) *w[i]
        end
    @inbounds covar[j,k] *= sumw/(sumw*sumw-sumw2)
    end
  end
  covar
end

# Compute weighted variances of sample (from origin)
function var_weighted(x::Array{Float64,2}, w::Array{Float64,1} )
  @assert(size(x,1)==length(w) )
  sumw = sum(w)
  @assert( sumw > 0. )
  if(sumw!= 1.0)
     w /= sum(w)
     sumw = 1.0
  end
  sumw2 = sum(w.*w)
  xbar = [ sum(x[:,i].*w) for i in 1:size(x,2) ]
  covar = zeros(size(x,2))
    for j in 1:size(x,2)
        for i in 1:size(x,1)
            @inbounds covar[j] += (x[i,j]-xbar[j])*(x[i,j]-xbar[j]) *w[i]
        end
    @inbounds covar[j] *= sumw/(sumw*sumw-sumw2)
    end
  covar
end

function make_matrix_pd(A::Array{Float64,2}; epsabs::Float64 = 0.0, epsfac::Float64 = 1.0e-6)
  @assert(size(A,1)==size(A,2))
  println("make_matrix_pd input: ", A)
  flush(STDOUT)
  B = 0.5*(A+A')
  itt = 1
  while !isposdef(B)
	eigvalB,eigvecB = eig(B)
        pos_eigval_idx = eigvalB.>0.0
	neweigval = (epsabs == 0.0) ? epsfac*minimum(abs.(eigvalB[pos_eigval_idx])) : epsabs
	eigvalB[.!pos_eigval_idx] = neweigval
	B = eigvecB *diagm(eigvalB)*eigvecB'
	println(itt,": ",B)
        flush(STDOUT)
        #cholB = chol(B)
	itt +=1
	if itt>size(A,1)
	  error("There's a problem in make_matrix_pd.\n")
  	  break
	end
  end
  return B
end

# Compute Effective Sample Size for array of weights
function ess(w::Array{Float64,1})
  sumw = sum(w)
  sumw2 = sum(w.*w)
  return sumw*sumw/sumw2
end


# Compute Effective Sample Size for array of weights, ignorring any repeated elements
function ess(w::Array{Float64,1}, repeat::Array{Int64,1} )
  @assert(length(w)==length(repeat))
  sumw = sum(w[findall(x->x==0,repeat)])
  sumw2 = sum(w[findall(x->x==0,repeat)].^2)
  return sumw*sumw/sumw2
end


# Common summary stats and distances
function calc_summary_stats_mean_var(x::Array{T,2} )  where T <:Real
 @inbounds m = mean(x,dims=2); 
 @inbounds v = var(x,2,mean=vec(m)); 
 return vcat(m, v)
end

function calc_summary_stats_mean_var(x::Array{T,1} )  where T <:Real
 @inbounds m = mean(x); 
 @inbounds v = var(x,mean=m); 
 return vcat(m, v)
end

calc_dist_max(x::Array{Float64},y::Array{Float64}) = maximum(abs.(x.-y))
dist_scale = Array{Float64}(undef,0)
calc_scaled_dist_max(x::Array{Float64,1},y::Array{Float64,1}, scale::Array{Float64,1} = dist_scale) = maximum(abs(x.-y)./scale)

function set_distance_scale(ds::Array{Float64,1})
  global dist_scale
  dist_scale = copy(ds)
end
function set_distance_scale( plan::abc_pmc_plan_type, theta::Array{Float64,1}; num_draw::Integer = 40,
                  ss::Array{T,1} = plan.calc_summary_stats(plan.gen_data(theta)) ) where T
  dist = Array{Float64}(undef,length(ss),num_draw)
  for i in 1:num_draw
    dist[:,i] = abs(ss.-plan.calc_summary_stats(plan.gen_data(theta)))
  end
  set_distance_scale(vec(median(dist,2)))
end


# Summary Stats & Distances based on Empirical CDF
# using Distributions
calc_summary_stats_ecdf(x::Array) = EmpiricalUnivariateDistribution(x)


function calc_dist_ks(x::EmpiricalUnivariateDistribution, y::EmpiricalUnivariateDistribution)
   maxd = 0.0
   for v in x.values
     d = abs(cdf(x,v)-cdf(y,v))
     if d>maxd maxd = d end
   end
   for v in y.values
     d = abs(cdf(x,v)-cdf(y,v))
     if d>maxd maxd = d end
   end
   maxd
end

function normalize_vector_of_log_values(x::Vector{Float64})
      logsum = logsumexp(x)
      param_vector = exp(param_vector-logsum)
end

