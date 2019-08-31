# Batched.jl

[![Build Status](https://travis-ci.org/Roger-luo/Batched.jl.svg?branch=master)](https://travis-ci.org/Roger-luo/Batched.jl)

Batched operations in Julia.

## Batched Arrays

- `BatchedArray{T, NI, N}` a general container that assumes the last `N - NI` dimensions are batch dimension
- `BatchedMatrix`, `BatchedVector`
- `BatchedTranspose`, `BatchedAdjoint`, `BatchedUniformScaling` batched version of them in stdlib: `LinearAlgebra`
- for cuda, defined type alias `CuBatchedArray`, `CuBatchedMatrix`, `CuBatchedVector`

## Supported routines

**(CPU)**: CPU implementations are just wrappers of for-loops.

- [x] batched `gemm`: `batched_gemm`
- [x] batched `tr`: `batched_tr`
- [x] batched `transpose`: `transpose(::AbstractArray{T, 3})`
- [x] batched `adjoint`

**(GPU)**: GPU implementations will use **CUBLAS** routines.

- [x] batched `gemm`: `batched_gemm_strided` (our `BatchedArray` can be assumed as strided)
- [ ] batched `tr`
- [x] batched `transpose` (same as CPU)
- [x] batched `adjoint` (same as CPU)

## Conventions

For routines (e.g `gemm`), we use a prefix `batched_` for their corresponding routines in `BLAS` or `LAPACK` and they should
only define with `AbstractArray{T, 3}` (batched matrix) or `AbstractArray{T, 2}` (batched vector).

For methods (e.g `LinearAlgebra.tr`), we simply overload them with a batched array type (e.g `BatchedArray`).

## License

Apache License Version 2.0
