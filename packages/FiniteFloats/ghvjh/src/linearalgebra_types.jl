for O in (:Adjoint, :Transpose,:Cholesky, :Hessenberg, :LDLt, :LQ, :LU, :QR)
    @eval LinearAlgebra.$O(::Type{T}) where {T} = LinearAlgebra.$O{T, Array{T,1}}
end

for O in (:BunchKaufman, :GeneralizedSVD, :Schur)
    @eval LinearAlgebra.$O(::Type{T}) where {T} = LinearAlgebra.$O{T, Array{T,2}}
end
