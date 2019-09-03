__precompile__()

module RandomCorrelationMatrices

    import LinearAlgebra: cholesky, diag, norm
    import Distributions

    """
        randcormatrix(d, η)

    Generate a d-by-d random correlation matrix using the
    method described in:

        Lewandowski, Kurowicka, Joe
          "Generating random correlation matrices based on vines
            and extended onion method"
        Journal of Multivariate Analysis 100 (2009)
        doi:10.1016/j.jmva.2009.04.008
    """
    function randcormatrix(d, η)
        β = η + (d - 2) / 2
        u = rand(Distributions.Beta(β, β))
        r₁₂ = 2 * u - 1
        r = [   1 r₁₂ ;
              r₁₂   1 ]
        # In published paper this index is n = 2:d-1. n is never mentioned
        # again, but a mysterious k is, so we'll thus use k. A similar approach
        # was taken here: http://stats.stackexchange.com/a/125017/58921
        for k in 2:d - 1
            β = β - 1 / 2
            y = rand(Distributions.Beta(k / 2, β))
            u = randn(k)
            u /= norm(u)
            w = sqrt(y) * u
            A = cholesky(r).L
            z = A * w
            r = [ r  z ;
                  z' 1 ]
        end
        return r
    end

    """
        randcovmatrix(d, η, σ)

    Use randcormatrix with desired vector of standard deviations σ
    for each term to generate a random covariance matrix.
    """
    function randcovmatrix(d, η, σ)
        length(σ) != d && throw(DimensionMismatch("length(σ) doesn't match d"))
        r = randcormatrix(d, η)
        Σ = zeros(d, d)
        @inbounds for i in 1:d, j in 1:d
            Σ[i,j] = r[i,j] * σ[i] * σ[j]
        end
        return Σ
    end

end  # module
