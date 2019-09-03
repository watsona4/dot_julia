"""
    PODBasis{T}(coefficients::Matrix{T}, modes::Matrix{T})

Datastructure to store a Proper Orthogonal Decomposition basis.

The original data which the POD basis is representing can be reconstructed by right-
multiplying the modes with the coefficients, i.e. `A = P.modes*P.coefficients`.
"""
struct PODBasis{T}
    coefficients::Matrix{T}
    modes::Matrix{T}
end
