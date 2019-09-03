################################################################################
#
#   Calculates integer coordinates in ℤⁿ lying inside the n
#          dimensional ellipsoid
#
#   Implementation of Remarks page 1426 of
#   B. Deconinck, M.  Heil, A. Bobenko, M. van Hoeij and M. Schmies,
#    Computing Riemann Theta Functions, Mathematics of Computation, 73, (2004),
#    1417-1442.
#
################################################################################

const padding = 0.5 # necessary for uniform approximation (page 1428)

function innerpoints(T::Matrix{Float64}, radius::Float64)
    n   = size(T, 1) # problem size

    # precalculate what is independent of points
    δcs = [ inv(T[1:i-1,1:i-1]) * T[1:i-1,i] for i in 1:n ]
    Tgg = diag(T)

    ns     = Vector{Float64}(undef, n)
    points = Vector{Float64}[]
    function _innerpoints(Rₒ, c, g)
        hw = Rₒ / Tgg[g]
        for ng in ceil(c[g]-hw):floor(c[g]+hw)
            ns[g] = ng
            if g == 1
                push!(points, copy(ns))
            else
                δcn = (ng - c[g])
                nc = c[1:g-1] - δcs[g] * δcn
                nsqRₒ = Rₒ^2 - (Tgg[g] * δcn)^2
                nsqRₒ > 0. && _innerpoints(sqrt(nsqRₒ), nc, g-1)
            end
        end
    end

    # add to initial R such that half-width 'hw' is augmented by 'padding'
    padded_Rₒ = radius / sqrt(π) + padding * Tgg[n]
    _innerpoints(padded_Rₒ, zeros(n), n)

    points
end
