
using Compat
using PDMats
using Distributions

if VERSION >= v"0.7"
  using Statistics
  using Distributed
  import Statistics: mean, median, maximum, minimum, quantile, std, var, cov, cor
else
  using Compat.Statistics
  using Compat.Distributed
  import Base: mean, median, maximum, minimum, quantile, std, var, cov, cor
end


#@compat abstract type GaussianMixtureModelCommonCovarAbstract <: Distribution end
@compat abstract type GaussianMixtureModelCommonCovarAbstract  <: Distribution{Multivariate,Continuous} end

struct GaussianMixtureModelCommonCovar <: GaussianMixtureModelCommonCovarAbstract
	mu::Array{Float64,2}
	probs::Vector{Float64}
        covar::AbstractPDMat
        aliastable::Distributions.AliasTable

    function GaussianMixtureModelCommonCovar(m::Array{Float64,2}, p::Vector{Float64}, ic::AbstractPDMat)
        if size(m,2) != length(p)
            error("means and probs must have the same number of elements")
        end
		if( size(ic,1) != size(ic,2) )
		    error("covariance matrix must be square")
		end 
		if( size(m,1) != size(ic,1) )
		    error("means and covar matrix not compatible sizes: ",size(m)," vs ",size(ic) )
		end
        sump = 0.0
        for i in 1:length(p)
            if p[i] < 0.0
                error("MixtureModel: probabilities must be non-negative")
            end
            sump += p[i]
        end
        table = Distributions.AliasTable(p)
        new(m, p ./ sump, ic, table)
    end

end

function GaussianMixtureModelCommonCovar(m::Array{Float64,2}, p::Vector{Float64}, ic::AbstractMatrix)
    GaussianMixtureModelCommonCovar(m,p,make_matrix_pd(ic))
end

function mean(d::GaussianMixtureModelCommonCovarAbstract)
    np = size(d.mu,2)
    m = zeros(np)
    for i in 1:length(d.probs)
        m += vec(d.mu[:,i]) .* d.probs[i]
    end
    return m
end

function pdf(d::GaussianMixtureModelCommonCovar, x::Array{Float64,1} )
    p = 0.0
    for i in 1:length(d.probs)
        if d.probs[i]<=0.0 continue end
        p += Distributions.pdf(Distributions.MvNormal(d.covar), x .- vec(d.mu[:,i]) ) * d.probs[i]
    end
    return p
end

function pdf(d::GaussianMixtureModelCommonCovar, x::Array{Float64,2} )
    np = size(x,2)
    p = zeros(np)
    for i in 1:length(d.probs)
        if d.probs[i]<=0.0 continue end
        p += Distributions.pdf(Distributions.MvNormal(d.covar), x .- vec(d.mu[:,i]) ) * d.probs[i]
    end
    return p
end

function logpdf(d::GaussianMixtureModelCommonCovar, x::Array{Float64,1})
    logp = -Inf
    for i in 1:length(d.probs)
        if d.probs[i]<=0.0 continue end
        logp_i = Distributions.logpdf(Distributions.MvNormal(d.covar), x .- vec(d.mu[:,i]) ) + log(d.probs[i])
        logp = logp > logp_i ? logp + log1p(exp(logp_i-logp)) : logp_i + log1p(exp(logp-logp_i))
    end
    return logp
end

function logpdf(d::GaussianMixtureModelCommonCovar, x::Array{Float64,2})
    np = size(x,2)
    logp = fill(-Inf,np)
    for i in 1:length(d.probs)
        if d.probs[i]<=0.0 continue end
        logp_i = Distributions.logpdf(Distributions.MvNormal(d.covar), x .- vec(d.mu[:,i]) ) + log(d.probs[i])
        for j in 1:length(logp)
          logp[j] = logp[j] > logp_i[j] ? logp[j] + log1p(exp(logp_i[j]-logp[j])) : logp_i[j] + log1p(exp(logp[j]-logp_i[j]))
        end
    end
    return logp
end

function rand(d::GaussianMixtureModelCommonCovar)
    i = Distributions.rand(d.aliastable)
    return  Distributions.rand(Distributions.MvNormal(vec(d.mu[:,i]),d.covar))
end


struct GaussianMixtureModelCommonCovarTruncated <: GaussianMixtureModelCommonCovarAbstract
	mu::Array{Float64,2}
	probs::Vector{Float64}
        covar::AbstractPDMat
        aliastable::Distributions.AliasTable
        max_mahalanobis::Float64

    function GaussianMixtureModelCommonCovarTruncated(m::Array{Float64,2}, p::Vector{Float64}, ic::AbstractPDMat, mm::Float64)
        if size(m,2) != length(p)
            error("means and probs must have the same number of elements")
        end
		if( size(ic,1) != size(ic,2) )
		    error("covariance matrix must be square")
		end 
		if( size(m,1) != size(ic,1) )
		    error("means and covar matrix not compatible sizes: ",size(m)," vs ",size(ic) )
		end
        sump = 0.0
        for i in 1:length(p)
            if p[i] < 0.0
                error("MixtureModel: probabilities must be non-negative")
            end
            sump += p[i]
        end
        table = Distributions.AliasTable(p)
        new(m, p ./ sump, ic, table, mm)
    end
end

function GaussianMixtureModelCommonCovarTruncated(m::Array{Float64,2}, p::Vector{Float64}, ic::AbstractMatrix, mm::Float64)
    GaussianMixtureModelCommonCovarTruncated(m, p, make_matrix_pd(ic), mm)
end

function pdf(d::GaussianMixtureModelCommonCovarTruncated, x::Array{Float64,1} )
    p = 0.0
    normalization = cdf(Distributions.Chisq(length(x)),d.max_mahalanobis)
    for i in 1:length(d.probs)
        if d.probs[i]<=0.0 continue end
        di = Distributions.MvNormal(vec(d.mu[:,i]),d.covar)
        if sqmahal(di, x) > d.max_mahalanobis continue end
        p += Distributions.pdf(di, x ) * d.probs[i] / normalization
    end
    return p  
end

function pdf(d::GaussianMixtureModelCommonCovarTruncated, x::Array{Float64,2} )
    np = size(x,2)
    p = zeros(np)
    normalization = cdf(Distributions.Chisq(length(x)),d.max_mahalanobis)
    for i in 1:length(d.probs)
        if d.probs[i]<=0.0 continue end
        di = Distributions.MvNormal(vec(d.mu[:,i]),d.covar)
        p += sqmahal(di, x) .> d.max_mahalanobis ? Distributions.pdf(di, x ) * d.probs[i] / normalization : 0.0
    end
    return p
end

function logpdf(d::GaussianMixtureModelCommonCovarTruncated, x::Array{Float64,1})
    logp = -Inf
    log_normalization = logcdf(Distributions.Chisq(length(x)),d.max_mahalanobis)
    for i in 1:length(d.probs)
        if d.probs[i]<=0.0 continue end
        di = Distributions.MvNormal(vec(d.mu[:,i]),d.covar)
        if sqmahal(di, x) > d.max_mahalanobis continue end
        logp_i = Distributions.logpdf(di, x) + log(d.probs[i]) - log_normalization
        logp = logp > logp_i ? logp + log1p(exp(logp_i-logp)) : logp_i + log1p(exp(logp-logp_i))
    end
    return logp
end

function logpdf(d::GaussianMixtureModelCommonCovarTruncated, x::Array{Float64,2})
    np = size(x,2)
    logp = fill(-Inf,np)
    log_normalization = logcdf(Distributions.Chisq(length(x)),d.max_mahalanobis)
    for i in 1:length(d.probs)
        if d.probs[i]<=0.0 continue end
        di = Distributions.MvNormal(vec(d.mu[:,i]),d.covar)
        logp_i = Distributions.logpdf(di, x) + log(d.probs[i]) - log_normalization
        for j in 1:length(logp)
          if sqmahal(di, x[:,j]) > d.max_mahalanobis continue end
          logp[j] = logp[j] > logp_i[j] ? logp[j] + log1p(exp(logp_i[j]-logp[j])) : logp_i[j] + log1p(exp(logp[j]-logp_i[j]))
        end
    end
    return logp
end

function rand(d::GaussianMixtureModelCommonCovarTruncated)
    @assert d.max_mahalanobis > 0.1
    i = Distributions.rand(d.aliastable)
    di = Distributions.MvNormal(vec(d.mu[:,i]),d.covar)
    local rv
    dist = Inf
    while dist > d.max_mahalanobis
      rv = Distributions.rand(di)
      dist = sqmahal(di, rv)
    end
    return rv
end




struct GaussianMixtureModelCommonCovarSubset <: GaussianMixtureModelCommonCovarAbstract
	mu::Array{Float64,2}
	probs::Vector{Float64}
        covar::AbstractPDMat
        aliastable::Distributions.AliasTable
        param_active::Vector{Int64}

     function GaussianMixtureModelCommonCovarSubset(m::Array{Float64,2}, p::Vector{Float64}, ic::AbstractArray{Float64,2}, pact::Vector{Int64} )
        if size(m,2) != length(p)
            error("means and probs must have the same number of elements")
        end
		if( size(ic,1) != size(ic,2) )
		    error("covariance matrix must be square")
		end 
        @assert(1<=length(pact)<=length(p))
        for idx in pact
            if ! (1<=idx<=length(p))
               error("active parameter ",idx," not in range 1:",length(p))
            end
        end
        sump = 0.0
        for i in 1:length(p)
            if p[i] < 0.0
                error("MixtureModel: probabilities must be non-negative")
            end
            sump += p[i]
        end
        table = Distributions.AliasTable(p)
        covar_subset = PDMat(make_matrix_pd(ic[pact,pact]))
        new( m, p ./sump, covar_subset, table, copy(pact) )
     end
     function GaussianMixtureModelCommonCovarSubset(m::Array{Float64,2}, p::Vector{Float64}, ic::AbstractArray{Float64,1}, pact::Vector{Int64} )
        if size(m,2) != length(p)
            error("means and probs must have the same number of elements")
        end
        @assert(1<=length(pact)<=length(p))
        for idx in pact
            if ! (1<=idx<=length(p))
               error("active parameters not in range 1:",length(p))
            end
        end
        sump = 0.0
        for i in 1:length(p)
            if p[i] < 0.0
                error("MixtureModel: probabilities must be non-negative")
            end
            sump += p[i]
        end
        table = Distributions.AliasTable(p)
        covar_subset = PDiagMat(ic[pact])
        new( m, p, covar_subset, table, copy(pact) )
     end
end


function mean(d::GaussianMixtureModelCommonCovarSubset)
    m = copy(x)
    for i in 1:length(d.probs)
        m += vec(d.mu[:,i]) .* d.probs[i]
    end
    return m
end

function pdf(d::GaussianMixtureModelCommonCovarSubset, x::Vector{Float64} )
    p = 0.0
    for i in 1:length(d.probs)
        if d.probs[i]<=0.0 continue end
        p += Distributions.pdf(Distributions.MvNormal(d.covar), x[d.param_active] .- vec(d.mu[d.param_active,i]) ) * d.probs[i]
    end
    return p
end

function pdf(d::GaussianMixtureModelCommonCovarSubset, x::Array{Float64,2} )
    np = size(x,2)
    p = zeros(np)
    for i in 1:length(d.probs)
        if d.probs[i]<=0.0 continue end
        p += Distributions.pdf(Distributions.MvNormal(d.covar), x[d.param_active,:] .- vec(d.mu[d.param_active,i]) ) * d.probs[i]
    end
    return p
end

function logpdf(d::GaussianMixtureModelCommonCovarSubset, x::Vector{Float64})
    logp = -Inf
    for i in 1:length(d.probs)
        if d.probs[i]<=0.0 continue end
        logp_i = Distributions.logpdf(Distributions.MvNormal(d.covar), x[d.param_active] .- vec(d.mu[d.param_active,i]) ) + log(d.probs[i])
        logp = logp > logp_i ? logp + log1p(exp(logp_i-logp)) : logp_i + log1p(exp(logp-logp_i))
    end
    return logp
end

function logpdf(d::GaussianMixtureModelCommonCovarSubset, x::Array{Float64,2})
    np = size(x,2)
    logp = fill(-Inf,np)
    for i in 1:length(d.probs)
        if d.probs[i]<=0.0 continue end
        logp_i = Distributions.logpdf(Distributions.MvNormal(d.covar), x[d.param_active,:] .- vec(d.mu[d.param_active,i]) ) + log(d.probs[i])
        for j in 1:length(logp)
          logp[j] = logp[j] > logp_i[j] ? logp[j] + log1p(exp(logp_i[j]-logp[j])) : logp_i[j] + log1p(exp(logp[j]-logp_i[j]))
        end
    end
    return logp
end

# Need to know dimension
function rand(d::GaussianMixtureModelCommonCovarSubset)
    i = Distributions.rand(d.aliastable)
    param = vec(d.mu[:,i])
    #println("# rand:  mu = ", d.mu[:,i], " Sigma = ", d.covar)
    param[d.param_active] = Distributions.rand(Distributions.MvNormal(vec(d.mu[d.param_active,i]),d.covar))
    return param
end
