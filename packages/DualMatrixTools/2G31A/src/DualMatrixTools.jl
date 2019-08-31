module DualMatrixTools

using DualNumbers, LinearAlgebra, SparseArrays, SuiteSparse

# Personal add-on: Allow for multiplication by ε of a sparse matrix
import Base.*
"""
    *(d::Dual, M::SparseMatrixCSC)

Exactly multiplies a sparse matrix `M` by the dual number `d`.
This overload allows `ε * M` to be non-zero.
(This is to correct the effect of the `ε == 0` feature in DualNumbers.jl,
which silently removes non-zeros from sparse matrices when multiplied by `ε`.)
"""
function *(d::Dual, M::SparseMatrixCSC)
    i, j, v = findnz(M)
    m, n = size(M)
    return sparse(i, j, d .* v, m, n)
end
export *

"""
    DualFactors

Container type to work efficiently with backslash on dual-valued sparse matrices.

`factorize(M)` will create an instance containing
- `Af = factorize(realpart.(M))` — the factors of the real part
- `B = dualpart.(M)` — the dual part
for a dual-valued matrix `M`.

This is because only the factors of the real part are needed when solving a linear system of the type ``M x = b`` for a dual-valued matrix ``M = A + \\varepsilon B``.
In fact, the inverse of ``M`` is given by
``M^{-1} = (I - \\varepsilon A^{-1} B) A^{-1}``.
"""
mutable struct DualFactors{TAf,TB}
    Af::TAf # the factors of the real part
    B ::TB  # the ε part
end
export DualFactors

# Factorization functions
for f in (:lu, :qr, :cholesky, :factorize)
    @eval begin
        import LinearAlgebra: $f
        """
        $($f)(M::SparseMatrixCSC{<:Dual,<:Int})

        Invokes `$($f)` on just the real part of `M` and stores it along with the dual part into a `DualFactors` object.
        """
        $f(M::SparseMatrixCSC{<:Dual,<:Int}) = DualFactors($f(realpart.(M)), dualpart.(M))
        """
        $($f)(M::Array{<:Dual,2})

        Invokes `$($f)` on just the real part of `M` and stores it along with the dual part into a `DualFactors` object.
        """
        $f(M::Array{<:Dual,2}) = DualFactors($f(realpart.(M)), dualpart.(M))
        export $f
    end
end

# In-place factorization for the case where the real part is already stored
import LinearAlgebra: factorize
function factorize(Mf::DualFactors, M; update_factors = false)
    Mf.B = dualpart.(M)
    if update_factors
        Mf.Af = factorize(realpart.(M))
    end
    return Mf
end
export factorize

# Adjoint and transpose definitions for `DualFactors`
for f in (:adjoint, :transpose)
    @eval begin
        import Base: $f
        """
        $($f)(M::DualFactors)

        Invokes `$($f)` on both `M.Af` and `M.B` and returns them into a new `DualFactors` object.
        """
        $f(M::DualFactors) = DualFactors($f(M.Af), $f(M.B))
        export $f
    end
end

import Base.\
"""
    \\(M::DualFactors, y::AbstractVecOrMat{Float64})

Backsubstitution for `DualFactors`.
See `DualFactors` for details.
"""
function \(M::DualFactors, y::AbstractVecOrMat{Float64})
    A, B = M.Af, M.B
    A⁻¹y = A \ y
    return A⁻¹y - ε * (A \ (B * A⁻¹y))
end

"""
    \\(M::DualFactors, y::AbstractVecOrMat{Dual128})

Backsubstitution for `DualFactors`.
See `DualFactors` for details.
"""
function \(M::DualFactors, y::AbstractVecOrMat{Dual128})
    a, b = realpart.(y), dualpart.(y)
    A, B = M.Af, M.B
    A⁻¹a = A \ a
    return A⁻¹a + ε * (A \ (b - B * A⁻¹a))
end

"""
    \\(Af::Factorization{Float64}, y::AbstractVecOrMat{Dual128})

Backsubstitution for Dual-valued RHS.
"""
function \(Af::Factorization{Float64}, y::AbstractVecOrMat{Dual128})
    return (Af \ realpart.(y)) + ε * (Af \ dualpart.(y))
end

"""
    \\(M::AbstractArray{Dual128,2}, y::AbstractVecOrMat)

Backslash (factorization and backsubstitution) for Dual-valued matrix `M`.
"""
\(M::SparseMatrixCSC{<:Dual,<:Int}, y::AbstractVecOrMat) = factorize(M) \ y
\(M::Array{<:Dual,2}, y::AbstractVecOrMat) = factorize(M) \ y
export \

import Base.isapprox
function isapprox(x::AbstractVecOrMat{Dual128}, y::AbstractVecOrMat{Dual128})
    bigx = [realpart.(x) dualpart.(x)]
    bigy = [realpart.(y) dualpart.(y)]
    return isapprox(bigx, bigy)
end
isapprox(x::AbstractVecOrMat, y::AbstractVecOrMat{Dual128}) = isapprox(dual.(x), y)
isapprox(x::AbstractVecOrMat{Dual128}, y::AbstractVecOrMat) = isapprox(x, dual.(y))
function isapprox(x::Dual128, y::Dual128)
    bigx = [realpart(x) dualpart(x)]
    bigy = [realpart(y) dualpart(y)]
    return isapprox(bigx, bigy)
end
isapprox(x::Float64, y::Dual128) = isapprox(dual(x), y)
isapprox(x::Dual128, y::Float64) = isapprox(x, dual(y))

end # module
