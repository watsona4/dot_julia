module FameSVD
using LinearAlgebra

export fsvd

function fsvd(A::Array{R, 2}) where R<:AbstractFloat
  dim = size(A)

  V = Array{R, 2}(undef, dim[2], dim[2])
  U = Array{R, 2}(undef, dim[1], dim[2])
  S = Array{R, 1}(undef, dim[2])

  V = BLAS.syrk('U', 'T', 1.0, A)
  (S, V) = LAPACK.syevr!('V', 'A', 'U', V, 0., 0., 0, 0, 0.)

  reverse!(S)
  @inbounds for i = 1:dim[2]
    @fastmath S[i] = sqrt(S[i])
  end

  V = reverse(V; dims = 2)
  U = BLAS.gemm('N', 'N', A, V)

  # TODO check if the loop order is optimal
  @inbounds for i = 1:dim[2]
    @inbounds for j = 1:dim[1]
      U[j, i] /= S[i]
    end
  end

  return LinearAlgebra.SVD(U, S, V')
end

end # module
