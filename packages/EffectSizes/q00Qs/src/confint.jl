bootstrapsample(xs::AbstractVector) = xs[rand(1:length(xs), length(xs))]

function twotailedquantile(quantile::AbstractFloat)
    0. ≤ quantile ≤ 1. || throw(DomainError(quantile))
    lq = (1-quantile)/2
    uq = quantile+lq
    lq, uq
end

"""
    AbstractConfidenceInterval{T<:Real}

A type representing a confidence interval.
"""
abstract type AbstractConfidenceInterval{T<:Real} end

"""
    lower(ci::AbstractConfidenceInterval)

Returns the lower bound of a confidence interval.
"""
lower(ci::AbstractConfidenceInterval) = ci.lower

"""
    upper(ci::AbstractConfidenceInterval)

Returns the upper bound of a confidence interval.
"""
upper(ci::AbstractConfidenceInterval) = ci.upper

"""
    confint(ci::AbstractConfidenceInterval)

Returns the lower and upper bounds of a confidence interval.
"""
HypothesisTests.confint(ci::AbstractConfidenceInterval) = lower(ci), upper(ci)

"""
    quantile(ci::AbstractConfidenceInterval)

Returns the quantile of a confidence interval.
"""
Distributions.quantile(ci::AbstractConfidenceInterval) = ci.quantile

function Base.show(io::IO, ci::AbstractConfidenceInterval)
    print(io, quantile(ci), "CI (", round(lower(ci), digits=PRECISION), ", ",
          round(upper(ci), digits=PRECISION), ")")
end

"""
    ConfidenceInterval(lower, upper, quantile)

A type representing the `lower` lower and `upper` upper bounds of an effect size confidence
interval at the `quantile` quantile.

    ConfidenceInterval(xs, ys, es; quantile)

Calculates a confidence interval for the effect size `es` between two vectors `xs` and `ys`
at the `quantile` quantile.
"""
struct ConfidenceInterval{T<:Real} <: AbstractConfidenceInterval{T}
    lower::T
    upper::T
    quantile::Float64

    function ConfidenceInterval(l::T,u::T,q::Float64) where T<:Real
        l ≤ u || throw(DomainError((l,u), "l > u"))
        0. ≤ q ≤ 1. || throw(DomainError(q))
        new{T}(l,u,q)
    end
end

function ConfidenceInterval(xs::AbstractVector{T}, ys::AbstractVector{T}, es::T;
                            quantile::AbstractFloat) where T<:Real
    0. ≤ quantile ≤ 1. || throw(DomainError(quantile))
    nx = length(xs)
    ny = length(ys)
    σ² = √(((nx+ny)/(nx*ny)) + (es^2 / 2(nx+ny)))
    _, uq = twotailedquantile(quantile)
    z = Distributions.quantile(Normal(), uq)
    ci = z*√σ²
    ConfidenceInterval(es-ci, es+ci, quantile)
end

"""
    BootstrapConfidenceInterval(lower, upper, quantile, bootstrap)

A type representing the `lower` lower and `upper` upper bounds of an effect size confidence
interval at the `quantile` quantile with `bootstrap` boostrap resamples.

    BootstrapConfidenceInterval(xs, ys, f, bootstrap; quantile)

Calculates the effect size confidence interval between two vectors `xs` and `ys` at the
`quantile` quantile by applying `f` to `bootstrap` bootstrap resamples of `xs` and `ys`.
"""
struct BootstrapConfidenceInterval{T<:Real} <: AbstractConfidenceInterval{T}
    lower::T
    upper::T
    quantile::Float64
    bootstrap::Int64

    function BootstrapConfidenceInterval(l::T,u::T,q::Float64,b::Int64) where T<:Real
        l ≤ u || throw(DomainError((l,u), "l > u"))
        0. ≤ q ≤ 1. || throw(DomainError(q))
        b > 1 || throw(DomainError(b))
        new{T}(l,u,q,b)
    end
end

function BootstrapConfidenceInterval(xs::AbstractVector{T}, ys::AbstractVector{T},
                                     f::Function, bootstrap::Integer=1000;
                                     quantile::AbstractFloat) where T<:Real
    0. ≤ quantile ≤ 1. || throw(DomainError(quantile))
    bootstrap > 1 || throw(DomainError(bootstrap))
    es = map(_->f(bootstrapsample(xs), bootstrapsample(ys)), 1:bootstrap)
    # es = @distributed vcat for _ = 1:bootstrap
    #     f(bootstrapsample(xs), bootstrapsample(ys))
    # end
    lq, uq = twotailedquantile(quantile)
    BootstrapConfidenceInterval(Distributions.quantile(es, lq),
        Distributions.quantile(es, uq), quantile, bootstrap)
end
