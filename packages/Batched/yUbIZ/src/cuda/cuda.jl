import CuArrays: CuArray
import CUDAdrv

const CuBatchedArray{T, NI, N} = BatchedArray{T, NI, N, CuArray{T, N}}
const CuBatchedMatrix{T, N} = CuBatchedArray{T, 2, N}
const CuBatchedVector{T, N} = CuBatchedArray{T, 1, N}
const CuBatchedVecOrMat{T, N} = Union{CuBatchedMatrix{T, N}, CuBatchedVector{T, N}}

include("routines/blas.jl")
include("matmul.jl")
