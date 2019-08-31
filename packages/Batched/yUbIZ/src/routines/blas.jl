# BLAS methods defined in this file should be all applied
# on a rank-2/rank-3 tensor: `AbstractArray{T, 3}`
# Other batched type should merge its batch dimension
# first before using routines defined here.

# routines in this file use the following name convention:
# prefix `batched` + _ + BLAS routine name in stdlib/LinearAlgebra/src/blas.jl

import LinearAlgebra.BLAS: BlasInt, BlasReal

function batched_syr! end

for (fname, elty, lib) in ((:dsyr_,:Float64, BLAS.libblas),
                           (:ssyr_,:Float32, BLAS.libblas),
                           (:zsyr_,:ComplexF64, BLAS.liblapack),
                           (:csyr_,:ComplexF32, BLAS.liblapack))

   @eval begin
       function batched_syr!(uplo::AbstractChar, α::$elty, x::AbstractMatrix{$elty}, A::AbstractArray{$elty, 3})
           @assert !BLAS.has_offset_axes(A, x)
           @assert size(A, 1) == size(A, 2)
           @assert size(x, 2) == size(A, 3)

           n = size(A, 1)
           if size(x, 1) != n
               throw(DimensionMismatch("A has size ($n,$n), x has length $(size(x, 1))"))
           end

           ptrA = Base.unsafe_convert(Ptr{$elty}, A)
           ptrX = Base.unsafe_convert(Ptr{$elty}, x)

           for k in 1:size(A, 3)
               ccall((BLAS.@blasfunc($fname), $lib), Cvoid,
                   (Ref{UInt8}, Ref{BlasInt}, Ref{$elty}, Ptr{$elty},
                    Ref{BlasInt}, Ptr{$elty}, Ref{BlasInt}),
                    uplo, n, α, ptrX,
                    stride(x, 1), ptrA, max(1,stride(A, 2)))

               ptrA += size(A, 1) * size(A, 2) * sizeof($elty)
               ptrX += size(x, 1) * sizeof($elty)
           end
           A
       end
   end
end


"""
    batched_gemm(A, B)
    batched_gemm(tA, tB, A, B)
    batched_gemm(tA, tB, alpha, A, B)

Batched version of `BLAS.gemm`.
"""
function batched_gemm end

"""
    batched_gemm!(transA, transB, alpha, A, B, beta, C)

Batched version of `BLAS.gemm!`.
"""
function batched_gemm! end

batched_gemm(A::AbstractArray{T, 3}, B::AbstractArray{T, 3}) where T =
    batched_gemm('N', 'N', A, B)
batched_gemm(transA::AbstractChar, transB::AbstractChar, A::AbstractArray{T, 3}, B::AbstractArray{T, 3}) where T =
    batched_gemm(transA, transB, one(T), A, B)

function batched_gemm(transA::AbstractChar, transB::AbstractChar, alpha::T, A::AbstractArray{T, 3}, B::AbstractArray{T, 3}) where T
    @assert size(A, 3) == size(B, 3) "Batch size mismatch"
    batched_gemm!(transA, transB, alpha, A, B, one(T), similar(B, (size(A, 1), size(B, 2), size(A, 3))))
end

function batched_gemm(tA::AbstractChar, tB::AbstractChar, alpha::T, A::BatchedMatrix{T}, B::BatchedMatrix{T}) where T
    data = similar(A.parent, (size(A, 1), size(B, 2), batch_size(A)...))
    fill!(data, zero(T))
    output = BatchedMatrix(data)
    batched_gemm!(tA, tB, alpha, A, B, one(T), output)
end

for (gemm, elty) in
        ((:dgemm_,:Float64),
         (:sgemm_,:Float32),
         (:zgemm_,:ComplexF64),
         (:cgemm_,:ComplexF32))
    @eval begin
        function batched_gemm!(transA::AbstractChar, transB::AbstractChar, alpha::($elty), A::AbstractArray{$elty, 3}, B::AbstractArray{$elty, 3}, beta::($elty), C::AbstractArray{$elty, 3})
            @assert !BLAS.has_offset_axes(A, B, C)
            @assert size(A, 3) == size(B, 3) == size(C, 3) "batch size mismatch"
            m = size(A, transA == 'N' ? 1 : 2)
            ka = size(A, transA == 'N' ? 2 : 1)
            kb = size(B, transB == 'N' ? 1 : 2)
            n = size(B, transB == 'N' ? 2 : 1)
            if ka != kb || m != size(C,1) || n != size(C,2)
                throw(DimensionMismatch("A has size ($m,$ka), B has size ($kb,$n), C has size $(size(C))"))
            end
            BLAS.chkstride1(A)
            BLAS.chkstride1(B)
            BLAS.chkstride1(C)

            ptrA = Base.unsafe_convert(Ptr{$elty}, A)
            ptrB = Base.unsafe_convert(Ptr{$elty}, B)
            ptrC = Base.unsafe_convert(Ptr{$elty}, C)

            for k in 1:size(A, 3)
                ccall((LinearAlgebra.BLAS.@blasfunc($gemm), BLAS.libblas), Cvoid,
                    (Ref{UInt8}, Ref{UInt8}, Ref{BLAS.BlasInt}, Ref{BLAS.BlasInt},
                     Ref{BLAS.BlasInt}, Ref{$elty}, Ptr{$elty}, Ref{BLAS.BlasInt},
                     Ptr{$elty}, Ref{BLAS.BlasInt}, Ref{$elty}, Ptr{$elty},
                     Ref{BLAS.BlasInt}),
                     transA, transB, m, n,
                     ka, alpha, ptrA, max(1,stride(A,2)),
                     ptrB, max(1,stride(B,2)), beta, ptrC,
                     max(1,stride(C,2)))

                ptrA += size(A, 1) * size(A, 2) * sizeof($elty)
                ptrB += size(B, 1) * size(B, 2) * sizeof($elty)
                ptrC += size(C, 1) * size(C, 2) * sizeof($elty)
            end
            C
        end
        function batched_gemm(transA::AbstractChar, transB::AbstractChar, alpha::($elty), A::AbstractArray{$elty, 3}, B::AbstractArray{$elty, 3})
            batched_gemm!(transA, transB, alpha, A, B, zero($elty), similar(B, $elty, (size(A, transA == 'N' ? 1 : 2), size(B, transB == 'N' ? 2 : 1), size(B, 3))))
        end
        function batched_gemm(transA::AbstractChar, transB::AbstractChar, A::AbstractArray{$elty, 3}, B::AbstractArray{$elty, 3})
            batched_gemm(transA, transB, one($elty), A, B)
        end
    end
end
