module AltDistributions

export AltMvNormal, LKJL, StdCorrFactor

using ArgCheck: @argcheck
import Base: \, size, getindex
import Distributions: logpdf
using DocStringExtensions: SIGNATURES
using LinearAlgebra
using LinearAlgebra: checksquare, AbstractTriangular
import LinearAlgebra: logdet
using Parameters: @unpack


# utilities

"""
Types accepted as a factor `L` of a covariance matrix `Σ=LL'`.
"""
const CovarianceFactor = Union{UniformScaling, AbstractMatrix}

"""
$(SIGNATURES)

Check that `μ` and `L::CovarianceFactor` have conforming dimensions (eg for `AltMvNormal`).

Used internally.
"""
function conforming_μL(μ::AbstractVector, L::AbstractMatrix)
    n = length(μ)
    size(L) == (n, n)
end

conforming_μL(μ::AbstractVector, ::UniformScaling) = true

struct StdCorrFactor{V <: AbstractVector, S <: CovarianceFactor, T} <: AbstractMatrix{T}
    σ::V
    F::S
    @doc """
    $(SIGNATURES)

    A factor `L` of a covariance matrix `Σ = LL'` given as `L = Diagonal(σ) * F`. Can be
    used in place of `L`, without performing the multiplication.
    """
    function StdCorrFactor(σ::V, F::S) where {V <: AbstractVector, S <: CovarianceFactor}
        T = typeof(one(eltype(F)) * one(eltype(σ)))
        @argcheck conforming_μL(σ, F)
        new{V,S,T}(σ, F)
    end
end

\(L::StdCorrFactor, y::Union{AbstractVector,AbstractMatrix}) = L.F \ (L.σ .\ y)

size(L::StdCorrFactor) = (n = length(L.σ); (n, n))

getindex(L::StdCorrFactor, I::Vararg{Int,2}) = getindex(Diagonal(L.σ) * L.F, I...) # just for printing

logdet(L::StdCorrFactor) = sum(log, L.σ) + logdet(L.F)


# AltMvNormal

struct AltMvNormal{M <: AbstractVector,T <: CovarianceFactor}
    "mean"
    μ::M
    "Cholesky factor, `L*L'` is the variance matrix. `L` can be *any* conformable matrix
    (or matrix-like object, eg UniformScaling), triangularity etc are not imposed."
    L::T
    @doc """
    $(SIGNATURES)

    Inner constructor used internally, for specifying `L` directly when the first argument is `Val{:L}`.

    You **don't want to use this unless you obtain `L` directly**. Use a `Cholesky` factorization instead.
    """
    function AltMvNormal(::Val{:L}, μ::M, L::T) where {M <: AbstractVector,
                                                       T <: CovarianceFactor}
        @argcheck conforming_μL(μ, L) "Non-conformable mean and variance factor."
        new{M, T}(μ, L)
    end
end

AltMvNormal(μ::AbstractVector, Σ::Cholesky) = AltMvNormal(Val{:L}(), μ, Σ.L)

"""
$(SIGNATURES)

Multivariate normal distribution with mean `μ` and covariance matrix `Σ`, which can be an
abstract matrix (eg a factorization) or `I`. If `Σ` is not symetric because of numerical
error, wrap in `LinearAlgebra.Symmetric`.

Use the `AltMvNormal(Val(:L), μ, L)` constructor for using `LL'=Σ` directly.

Also, see [`StdCorrFactor`](@ref) for formulating `L` from standard deviations and a
Cholesky factor of a *correlation* matrix:

```julia
AltMvNormal(μ, StdCorrFactor(σ, S))
```
"""
function AltMvNormal(μ::AbstractVector, Σ::AbstractMatrix)
    @argcheck issymmetric(Σ) "Σ is not symmetric. Try wrapping in `LinearAlgebra.Symmetric`."
    AltMvNormal(μ, cholesky(Σ))
end

AltMvNormal(μ::AbstractVector, Σ::Diagonal) = AltMvNormal(Val{:L}(), μ, Diagonal(.√diag(Σ)))

AltMvNormal(μ::AbstractVector, ::UniformScaling) = AltMvNormal(Val{:L}(), μ, I)

function logpdf(d::AltMvNormal, x::AbstractVector)
    @unpack μ, L = d
    -0.5*length(μ)*log(2*π) - logdet(L) - 0.5*sum(abs2, L \ (x .- μ))
end


# LKJL

struct LKJL{T <: Real}
    η::T
    @doc """
        $(SIGNATURES)

    The LKJ distribution (Lewandowski et al 2009) for the Cholesky factor L of correlation
    matrices.

    A correlation matrix ``Ω=LL'`` has the density ``|Ω|^{η-1}``. However, it is usually not
    necessary to construct ``Ω``, so this distribution is formulated for the Cholesky
    decomposition `L*L'`, and takes `L` directly.

    Note that the methods **does not check if `L` yields a valid correlation matrix**.

    Valid values are ``η > 0``. When ``η > 1``, the distribution is unimodal at `Ω=I`, while
    ``0 < η < 1`` has a trough. ``η = 2`` is recommended as a vague prior.

    When ``η = 1``, the density is uniform in `Ω`, but not in `L`, because of the Jacobian
    correction of the transformation.
    """
    function LKJL(η::T) where T <: Real
        @argcheck η > 0
        new{T}(η)
    end
end

function logpdf(d::LKJL, L::Union{AbstractTriangular, Diagonal})
    @unpack η = d
    z = diag(L)
    n = size(L, 1)
    sum(log.(z) .* ((n:-1:1) .+ 2*(η-1))) + log(2) * n
end

end # module
