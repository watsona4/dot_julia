module RandomBooleanMatrices

using Random
using RandomNumbers.Xorshifts
using SparseArrays
using StatsBase

include("curveball.jl")

@enum matrixrandomizations curveball

"""
    randomize_matrix!(m; method = curveball)

Randomize the sparse boolean Matrix `m` while maintaining row and column sums
"""
function randomize_matrix!(m::SparseMatrixCSC{Bool, Int}, rng = Random.GLOBAL_RNG; method::matrixrandomizations = curveball)
    if method == curveball
        return _curveball!(m, rng)
    end
    error("undefined method")
end


SparseMatrixCSC{Bool, Int}

struct MatrixGenerator{R<:AbstractRNG, M}
    m::M
    method::matrixrandomizations
    rng::R
end

show(io::IO, m::MatrixGenerator{R, SparseMatrixCSC{Bool, Int}}) where R = println(io, "Boolean MatrixGenerator with size $(size(m.m)) and $(nnz(m.m)) occurrences")

"""
    matrixrandomizer(m [,rng]; method = curveball)

Create a matrix generator function that will return a random boolean matrix
every time it is called, maintaining row and column sums. Non-boolean input
matrix are interpreted as boolean, where values != 0 are `true`.

# Examples
```
m = rand(0:4, 5, 6)
rmg = matrixrandomizer(m)

random1 = rand(rmg)
random2 = rand(rmg)
``
"""
matrixrandomizer(m, rng) = error("No matrixrandomizer defined for $(typeof(m))")
matrixrandomizer(m) = error("No matrixrandomizer defined for $(typeof(m))")
matrixrandomizer(m::AbstractMatrix, rng = Xoroshiro128Plus(); method::matrixrandomizations = curveball) =
    MatrixGenerator{typeof(rng), SparseMatrixCSC{Bool, Int}}(dropzeros!(sparse(m)), method, rng)
matrixrandomizer(m::SparseMatrixCSC{Bool, Int}, rng = Xoroshiro128Plus(); method::matrixrandomizations = curveball) =
    MatrixGenerator{typeof(rng), SparseMatrixCSC{Bool, Int}}(dropzeros(m), method, rng)

Random.rand(r::MatrixGenerator{R, SparseMatrixCSC{Bool, Int}}; method::matrixrandomizations = curveball) where R = copy(randomize_matrix!(r.m, r.rng, method = r.method))
Random.rand!(r::MatrixGenerator{R, SparseMatrixCSC{Bool, Int}}; method::matrixrandomizations = curveball) where R = randomize_matrix!(r.m, r.rng, method = r.method)

export randomize_matrix!, matrixrandomizer, matrixrandomizations
export curveball

end
