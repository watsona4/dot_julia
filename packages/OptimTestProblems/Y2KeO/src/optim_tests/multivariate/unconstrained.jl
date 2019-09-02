module UnconstrainedProblems

import ..OptimizationProblem

export OptimizationProblem

import LinearAlgebra: Diagonal, qr, dot
import SparseArrays: sparse
import Test: guardseed

import ..objective, ..gradient, ..hessian

examples = Dict{AbstractString, OptimizationProblem}()

include("from_optim.jl")
include("quad_transforms.jl")
include("more_testing.jl")
end # module
