module Qutilities

using LinearAlgebra: eigvals, Hermitian, svdvals, tr

export
    binent,
    concurrence,
    concurrence_lb,
    formation,
    mutinf,
    negativity,
    ptrace,
    ptranspose,
    purity,
    sigma_x,
    sigma_y,
    sigma_z,
    spinflip,
    S_renyi,
    S_vn


# All logarithms are base 2.
const LOG = log2

"""
    hermitize(rho::AbstractMatrix)

Make `rho` Hermitian, but carefully.
"""
function hermitize(rho::AbstractMatrix)
    size(rho, 1) == size(rho, 2) || throw(DomainError(size(rho), "Only square matrices are supported."))

    err = maximum(abs.(rho - rho'))
    if err > 1e-12
        @warn "Matrix is not Hermitian: $(err)"
    end

    # Make the diagonal strictly real.
    rho_H = copy(rho)
    for i in 1:size(rho_H, 1)
        rho_H[i, i] = real(rho_H[i, i])
    end

    Hermitian(rho_H)
end

"""
    nonneg(x::Real)

`x` if `x` is non-negative; zero if `x` is negative.
"""
nonneg(x::Real) = x < 0 ? zero(x) : x

"""
    shannon(xs::AbstractVector)

Shannon entropy of `xs`.
"""
shannon(xs::AbstractVector) = -sum([x * LOG(x) for x in xs if x > 0])


# Single-qubit Pauli matrices.
const sigma_x = [[0.0, 1.0] [1.0, 0.0]]
const sigma_y = [[0.0, im] [-im, 0.0]]
const sigma_z = [[1.0, 0.0] [0.0, -1.0]]

"""
    ptrace(rho::AbstractMatrix{T}, dims, which::Int)

Partial trace of `rho` along dimension `which` from `dims`.
"""
function ptrace(rho::AbstractMatrix{T}, dims, which::Int) where {T}
    size(rho) == (prod(dims), prod(dims)) || throw(DomainError(size(rho), "Only square matrices are supported."))

    size_before = prod(dims[1:(which-1)])
    size_at = dims[which]
    size_after = prod(dims[(which+1):end])

    result = zeros(T, size_before*size_after, size_before*size_after)
    for i1 in 1:size_before
        for j1 in 1:size_before
            for k in 1:size_at
                for i2 in 1:size_after
                    for j2 in 1:size_after
                        row1 = size_after*(i1-1) + i2
                        col1 = size_after*(j1-1) + j2
                        row2 = size_at*size_after*(i1-1) + size_after*(k-1) + i2
                        col2 = size_at*size_after*(j1-1) + size_after*(k-1) + j2
                        result[row1, col1] += rho[row2, col2]
                    end
                end
            end
        end
    end
    result
end

"""
    ptrace(rho::AbstractMatrix, which::Int=2)

Partial trace of `rho` along dimension `which`.

`rho` is split into halves and the trace is over the second half by default.
"""
function ptrace(rho::AbstractMatrix, which::Int=2)
    size(rho, 1) % 2 == 0 || throw(DomainError(size(rho, 1), "Matrix size must be even."))

    s = div(size(rho, 1), 2)
    ptrace(rho, (s, s), which)
end

"""
    ptranspose(rho::AbstractMatrix, dims, which::Int)

Partial transpose of `rho` along dimension `which` from `dims`.
"""
function ptranspose(rho::AbstractMatrix, dims, which::Int)
    size(rho) == (prod(dims), prod(dims)) || throw(DomainError(size(rho), "Only square matrices are supported."))

    size_before = prod(dims[1:(which-1)])
    size_at = dims[which]
    size_after = prod(dims[(which+1):end])

    result = similar(rho)
    for i1 in 1:size_before
        for j1 in 1:size_before
            for i2 in 1:size_at
                for j2 in 1:size_at
                    for i3 in 1:size_after
                        for j3 in 1:size_after
                            row1 = size_at*size_after*(i1-1) + size_after*(i2-1) + i3
                            col1 = size_at*size_after*(j1-1) + size_after*(j2-1) + j3
                            row2 = size_at*size_after*(i1-1) + size_after*(j2-1) + i3
                            col2 = size_at*size_after*(j1-1) + size_after*(i2-1) + j3
                            result[row1, col1] = rho[row2, col2]
                        end
                    end
                end
            end
        end
    end
    result
end

"""
    ptranspose(rho::AbstractMatrix, which::Int=2)

Partial transpose of `rho` along dimension `which`.

`rho` is split into halves and the transpose is over the second half by
default.
"""
function ptranspose(rho::AbstractMatrix, which::Int=2)
    size(rho, 1) % 2 == 0 || throw(DomainError(size(rho, 1), "Matrix size must be even."))

    s = div(size(rho, 1), 2)
    ptranspose(rho, (s, s), which)
end

"""
    binent(x::Real)

Binary entropy of `x`.
"""
binent(x::Real) = shannon([x, one(x) - x])

"""
    purity(rho::AbstractMatrix)

Purity of `rho`.
"""
purity(rho::AbstractMatrix) = rho^2 |> tr |> real

"""
    S_vn(rho::AbstractMatrix)

Von Neumann entropy of `rho`.
"""
S_vn(rho::AbstractMatrix) = rho |> hermitize |> eigvals |> shannon

"""
    S_renyi(rho::AbstractMatrix, alpha::Real=2)

Order `alpha` Rényi entropy of `rho`.

The `alpha` parameter may have any value on the interval `[0, Inf]` except 1.
It defaults to 2.
"""
function S_renyi(rho::AbstractMatrix, alpha::Real=2)
    E = rho |> hermitize |> eigvals
    alpha == Inf && return E |> maximum |> LOG |> -
    LOG(sum(E.^alpha)) / (1 - alpha)
end

"""
    mutinf(rho::AbstractMatrix, S::Function=S_vn)

Mutual information of `rho` using the entropy function `S`.
"""
function mutinf(rho::AbstractMatrix, S::Function=S_vn)
    S(ptrace(rho, 1)) + S(ptrace(rho, 2)) - S(rho)
end

"""
    spinflip(rho::AbstractMatrix)

Wootters spin-flip operation for two qubits in the mixed state `rho` in the
standard basis.

Ref: Wootters, W. K. (1998). Entanglement of formation of an arbitrary state of
two qubits. Physical Review Letters, 80(10), 2245.
"""
function spinflip(rho::AbstractMatrix)
    size(rho) == (4, 4) || throw(DomainError(size(rho), "Matrix must be 4 by 4."))

    Y = kron(sigma_y, sigma_y)
    Y * conj(rho) * Y
end

"""
    concurrence(rho::AbstractMatrix)

Concurrence of a mixed state `rho` for two qubits in the standard basis.

Ref: Wootters, W. K. (1998). Entanglement of formation of an arbitrary state of
two qubits. Physical Review Letters, 80(10), 2245.
"""
function concurrence(rho::AbstractMatrix)
    size(rho) == (4, 4) || throw(DomainError(size(rho), "Matrix must be 4 by 4."))

    E = rho * spinflip(rho) |> eigvals
    if any(imag(E) .> 1e-15)
        @warn "Complex eigenvalues: $(maximum(imag(E)))"
    end
    if any(real(E) .< -1e-12)
        @warn "Negative eigenvalues: $(minimum(real(E)))"
    end
    F = sort(sqrt.(nonneg.(real(E))))
    nonneg(F[end] - sum(F[1:(end-1)]))
end

"""
    concurrence_lb(rho::AbstractMatrix)

Lower bound on the concurrence for two qubits in the mixed state `rho` in the
standard basis.

Ref: Mintert, F., & Buchleitner, A. (2007). Observable entanglement measure for
mixed quantum states. Physical Review Letters, 98(14), 140505.
"""
function concurrence_lb(rho::AbstractMatrix)
    size(rho) == (4, 4) || throw(DomainError(size(rho), "Matrix must be 4 by 4."))

    2.0*(purity(rho) - purity(ptrace(rho))) |> nonneg |> sqrt
end

"""
    formation(C::Real)

Entanglement of formation for two qubits with concurrence `C`.

Ref: Wootters, W. K. (1998). Entanglement of formation of an arbitrary state of
two qubits. Physical Review Letters, 80(10), 2245.
"""
formation(C::Real) = binent(0.5 * (1.0 + sqrt(1.0 - C^2)))

"""
    formation(rho::AbstractMatrix)

Entanglement of formation for two qubits in the mixed state `rho` in the
standard basis.

Ref: Wootters, W. K. (1998). Entanglement of formation of an arbitrary state of
two qubits. Physical Review Letters, 80(10), 2245.
"""
formation(rho::AbstractMatrix) = rho |> concurrence |> formation

"""
    negativity(rho::AbstractMatrix)

Logarithmic negativity for a symmetric bipartition of `rho`.

Ref: Plenio, M. B. (2005). Logarithmic negativity: A full entanglement monotone
that is not convex. Physical Review Letters, 95(9), 090503.
"""
negativity(rho::AbstractMatrix) = rho |> ptranspose |> svdvals |> sum |> LOG

end
