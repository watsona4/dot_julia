const _CUDA_BATCHED_MATRIX_LIST = [
        (:CuBatchedMatrix, 'N'),
        (:(BatchedTranspose{T, N, <:CuBatchedMatrix} where N), 'T'),
        (:(BatchedAdjoint{T, N, <:CuBatchedMatrix} where N), 'C')
]

for (TA, transA) in _CUDA_BATCHED_MATRIX_LIST, (TB, transB) in _CUDA_BATCHED_MATRIX_LIST
    @eval function LinearAlgebra.mul!(C::CuBatchedMatrix{T}, A::$TA, B::$TB) where T
        @boundscheck check_batch_dim_size(A, B, C)
        batchA, batchB, batchC = merge_batch_dim(A), merge_batch_dim(B), merge_batch_dim(C)
        batched_gemm_strided!($transA, $transB, one(T), batchA, batchB, one(T), batchC)
        C
    end
end
