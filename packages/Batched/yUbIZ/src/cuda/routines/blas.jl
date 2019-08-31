import CuArrays.CUBLAS: @check, cublasop, cublasStatus_t, cublasHandle_t, cublasOperation_t, handle, libcublas

# function cublasSgemmStridedBatched(
#                handle, transA, transB,
#                m, n, k,
#                alpha,
#                A, lda, strideA,
#                B, ldb, strideB,
#                beta, C, ldc, strideC)
#
#   @check ccall((:cublasSgemmStridedBatched, libcublas),
#                cublasStatus_t,
#                (cublasHandle_t, cublasOperation_t, cublasOperation_t, Cint, Cint, Cint,
#                 Ptr{Cfloat}, Ptr{Cfloat}, Cint, Cint, Ptr{Cfloat}, Cint, Cint, Ptr{Cfloat}, Ptr{Cfloat},
#                 Cint, Cint),
#                handle, transa, transb, m, n, k, alpha, A, lda, strideA, B, ldb, strideB, beta, C, ldc, strideC)
# end

function batched_gemm_strided!(transA::Char,
               transB::Char,
               alpha::Float32,
               A::CuArray{Float32, 3},
               B::CuArray{Float32, 3},
               beta::Float32,
               C::CuArray{Float32, 3})
    m = size(A, transA == 'N' ? 1 : 2)
    k = size(A, transA == 'N' ? 2 : 1)
    n = size(B, transB == 'N' ? 2 : 1)

    @assert size(A, 3) == size(B, 3) == size(C, 3) "Batch size mismatch"

    if m != size(C,1) || n != size(C,2) || k != size(B, transB == 'N' ? 1 : 2)
        throw(DimensionMismatch(""))
    end
    cutransA = cublasop(transA)
    cutransB = cublasop(transB)
    lda = max(1,stride(A,2))
    ldb = max(1,stride(B,2))
    ldc = max(1,stride(C,2))

    strideA = stride(A, 3)
    strideB = stride(B, 3)
    strideC = stride(C, 3)
    batchCount = size(A, 3)
    @check ccall((:cublasSgemmStridedBatched, libcublas), cublasStatus_t,
                 (cublasHandle_t, cublasOperation_t,
                  cublasOperation_t, Cint, Cint, Cint, Ptr{Float32},
                  Ptr{Float32}, Cint, Cint, Ptr{Float32}, Cint, Cint, Ptr{Float32},
                  Ptr{Float32}, Cint, Cint, Cint),
                 handle(), cutransA,
                 cutransB, m, n, k, [alpha], A, lda, strideA, B, ldb, strideB, [beta],
                 C, ldc, strideC, batchCount)
    C
end
