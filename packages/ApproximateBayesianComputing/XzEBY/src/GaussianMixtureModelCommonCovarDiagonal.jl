# using Distributions

immutable GaussianMixtureModelCommonCovarDiagonal <: Distribution
    mu::Array{Float64,2}
    probs::Vector{Float64}
    covar::Vector{Float64}
    aliastable::Distributions.AliasTable
    function GaussianMixtureModelCommonCovarDiagonal(m::Array{Float64,2}, p::Vector{Float64}, ic::Vector{Float64})
        if size(m,2) != length(p)
            error("means and probs must have the same number of elements")
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

function mean(d::GaussianMixtureModelCommonCovarDiagonal)
    np = size(d.mu,2)
    m = zeros(np)
    for i in 1:length(d.probs)
        m += vec(d.mu[:,i]) .* d.probs[i]
    end
    return m
end

function pdf(d::GaussianMixtureModelCommonCovarDiagonal, x::Any)
    p = 0.0
    for i in 1:length(d.probs)
        p += Distributions.pdf(Distributions.MvNormal(sqrt(d.covar)), x .- vec(d.mu[:,i]) ) * d.probs[i]
    end
    return p
end

function rand(d::GaussianMixtureModelCommonCovarDiagonal)
    i = Distributions.rand(d.aliastable)
    return  Distributions.rand(Distributions.MvNormal(vec(d.mu[:,i]),sqrt(d.covar)))
end


