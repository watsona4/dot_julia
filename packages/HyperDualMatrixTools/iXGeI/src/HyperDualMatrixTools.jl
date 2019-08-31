module HyperDualMatrixTools

using HyperDualNumbers, LinearAlgebra, SparseArrays, SuiteSparse

# Personal add-on: Allow for multiplication by ε of a sparse matrix
import Base.*
"""
    *(d::Hyper, M::SparseMatrixCSC)

Exactly multiplies a sparse matrix `M` by the hyperdual number `d`.
This overload allows, e.g., `ε₁ * M` to be non-zero.
(This is to correct the effect of, e.g., the `ε₁ == 0` feature in HyperDualNumbers.jl,
which silently removes non-zeros from sparse matrices when multiplied by `ε₁`.)
"""
function *(h::Hyper, M::SparseMatrixCSC)
    i, j, v = findnz(M)
    m, n = size(M)
    return sparse(i, j, h .* v, m, n)
end
export *


"""
    HyperDualFactors

Container type to work efficiently with backslash on hyperdual-valued sparse matrices.

`factorize(M)` will create an instance containing
- `Af = factorize(realpart.(M))` — the factors of the real part
- `B = ε₁part.(M)` — the ``\\varepsilon_1`` part
- `C = ε₂part.(M)` — the ``\\varepsilon_2`` part
- `D = ε₁ε₂part.(M)` — the ``\\varepsilon_1\\varepsilon_2`` part
for a hyperdual-valued matrix `M`.

This is because only the factors of the real part are needed when solving a linear system of the type ``M x = b`` for a hyperdual-valued matrix ``M = A + \\varepsilon_1 B + \\varepsilon_2 C + \\varepsilon_1 \\varepsilon_2 D``.
In fact, the inverse of ``M`` is given by
``M^{-1} = (I - \\varepsilon_1 A^{-1} B - \\varepsilon_2 A^{-1} C - \\varepsilon_1\\varepsilon_2 A^{-1} (D - B A^{-1} C - C A^{-1} B)) A^{-1}``.
"""
mutable struct HyperDualFactors{TAf,T}
    Af::TAf # the factors of the real part
    B ::T   # the ε₁ part
    C ::T   # the ε₂ part
    D ::T   # the ε₁ε₂ part
end
export HyperDualFactors

# Factorization functions
for f in (:lu, :qr, :cholesky, :factorize)
    @eval begin
        import LinearAlgebra: $f
        """
        $($f)(M::SparseMatrixCSC{<:Hyper,<:Int})

        Invokes `$($f)` on just the real part of `M` and stores it along with the dual parts into a `HyperDualFactors` object.
        """
        $f(M::SparseMatrixCSC{<:Hyper,<:Int}) = HyperDualFactors($f(realpart.(M)), ε₁part.(M), ε₂part.(M), ε₁ε₂part.(M))
        """
        $($f)(M::Array{<:Hyper,2})

        Invokes `$($f)` on just the real part of `M` and stores it along with the dual parts into a `HyperDualFactors` object.
        """
        $f(M::Array{<:Hyper,2}) = HyperDualFactors($f(realpart.(M)), ε₁part.(M), ε₂part.(M), ε₁ε₂part.(M))
        export $f
    end
end

# In-place factorization for the case where the real part is already stored
import LinearAlgebra: factorize
function factorize(Mf::HyperDualFactors, M; update_factors = false)
    Mf.B = ε₁part.(M)
    Mf.C = ε₂part.(M)
    Mf.D = ε₁ε₂part.(M)
    if update_factors
        Mf.Af = factorize(realpart.(M))
    end
    return Mf
end
export factorize

# Adjoint and transpose definitions for `HyperDualFactors`
for f in (:adjoint, :transpose)
    @eval begin
        import Base: $f
        """
        $($f)(M::HyperDualFactors)

        Invokes `$($f)` on `M.Af`, `M.B`, `M.C`, and `M.D` and returns them into a new `HyperDualFactors` object.
        """
        $f(M::HyperDualFactors) = HyperDualFactors($f(M.Af), $f(M.B), $f(M.C), $f(M.D))
        export $f
    end
end

import Base.\
"""
    \\(M::HyperDualFactors, y::AbstractVecOrMat{Float64})

Backsubstitution for `HyperDualFactors`.
See `HyperDualFactors` for details.
"""
function \(M::HyperDualFactors, a::AbstractVecOrMat{Float64})
    A, B, C, D = M.Af, M.B, M.C, M.D
    A⁻¹a = A \ a
    _A⁻¹BA⁻¹a = A \ (-B * A⁻¹a)
    _A⁻¹CA⁻¹a = A \ (-C * A⁻¹a)
    return A⁻¹a + ε₁ * _A⁻¹BA⁻¹a + ε₂ * _A⁻¹CA⁻¹a +
        ε₁ε₂ * (A \ (-D * A⁻¹a - C * _A⁻¹BA⁻¹a - B * _A⁻¹CA⁻¹a))
end

"""
    \\(M::HyperDualFactors, y::AbstractVecOrMat{Hyper256})

Backsubstitution for `HyperDualFactors`.
See `HyperDualFactors` for details.
"""
function \(M::HyperDualFactors, y::AbstractVecOrMat{Hyper256})
    a, b, c, d = realpart.(y), ε₁part.(y), ε₂part.(y), ε₁ε₂part.(y)
    A, B, C, D = M.Af, M.B, M.C, M.D
    A⁻¹a = A \ a
    A⁻¹b_A⁻¹BA⁻¹a = A \ (b - B * A⁻¹a)
    A⁻¹c_A⁻¹CA⁻¹a = A \ (c - C * A⁻¹a)
    return A⁻¹a + ε₁ * A⁻¹b_A⁻¹BA⁻¹a + ε₂ * A⁻¹c_A⁻¹CA⁻¹a +
        ε₁ε₂ * (A \ (d - D * A⁻¹a - C * A⁻¹b_A⁻¹BA⁻¹a - B * A⁻¹c_A⁻¹CA⁻¹a))
end

"""
    \\(Af::Factorization{Float64}, y::AbstractVecOrMat{Hyper256})

Backsubstitution for HyperDual-valued RHS.
"""
function \(Af::Factorization{Float64}, y::AbstractVecOrMat{Hyper256})
    return (Af \ realpart.(y)) + ε₁ * (Af \ ε₁part.(y)) + ε₂ * (Af \ ε₂part.(y)) + ε₁ε₂ * (Af \ ε₁ε₂part.(y))
end

"""
    \\(M::AbstractArray{<:Hyper,2}, y::AbstractVecOrMat)

Backslash (factorization and backsubstitution) for Dual-valued matrix `M`.
"""
\(M::SparseMatrixCSC{<:Hyper,<:Int}, y::AbstractVecOrMat) = factorize(M) \ y
\(M::Array{<:Hyper,2}, y::AbstractVecOrMat) = factorize(M) \ y
export \

import Base.isapprox
function isapprox(x::AbstractVecOrMat{Hyper256}, y::AbstractVecOrMat{Hyper256})
    bigx = [realpart.(x) ε₁part.(x) ε₂part.(x) ε₁ε₂part.(x)]
    bigy = [realpart.(y) ε₁part.(y) ε₂part.(y) ε₁ε₂part.(y)]
    return isapprox(bigx, bigy)
end
isapprox(x::AbstractVecOrMat, y::AbstractVecOrMat{Hyper256}) = isapprox(hyper.(x), y)
isapprox(x::AbstractVecOrMat{Hyper256}, y::AbstractVecOrMat) = isapprox(x, hyper.(y))
function isapprox(x::Hyper256, y::Hyper256)
    bigx = [realpart(x) ε₁part(x) ε₂part(x) ε₁ε₂part(x)]
    bigy = [realpart(y) ε₁part(y) ε₂part(y) ε₁ε₂part(y)]
    return isapprox(bigx, bigy)
end
isapprox(x::Float64, y::Hyper256) = isapprox(hyper(x), y)
isapprox(x::Hyper256, y::Float64) = isapprox(x, hyper(y))

end # module
