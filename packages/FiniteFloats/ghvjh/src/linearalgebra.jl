for F in (:diag, :diagm, :logdet, :norm, :normalize, :normalize!, :pinv, :qr, :transpose)
   @eval $F(x::A) where {T<:AbstractFinite, A<:AbstractVector{T}} = T.($F(float(T).(x)))
end

for F in (:adjoint, :diag, :diagm, :expm, :exmp!, :logdet, :norm, :normalize, :normalize!,
          :nullspace, :pinv, :qr, :transpose)
   @eval $F(x::V) where {T<:AbstractFinite, V<:Vector{T}} = T.($F(float(T).(x)))
end

for F in (:adjoint, :bunchkaufman, :cond, :condskeel, :det, :diag, :diagind,
          :eigmax, :eigmin, :eigvecs, :expm, :expm!,
          :isdiag, :ishermitian, :isposdef, :isposdef!, :issymmetric, :istril, :istriu,
          :logabsdet, :logdet, :lu, :norm, :opnorm, :qr, :rank, :svdvals,
          :tr, :transpose, :tril, :tril!, :triu, :triu!)
   @eval $F(x::M) where {T<:AbstractFinite, M<:AbstractMatrix{T}} = T.($F(float(T).(x)))
end
          
for F in (:bunchkaufman, :cholesky, :cholesky!, :cond, :condskeel,
          :det, :diag, :diagind, :eigen, :eigmax, :eigmin, :eigvals, :eigvecs,
          :expm, :expm!, :factorize, :hessenberg, :isdiag, :ishermitian,
          :isposdef, :isposdef!, :issymmetric, :istril, :istriu, :logabsdet,
          :logdet, :lu, :lu!, :norm, :nullspace, :opnorm, :pinv, :qr, :qr!,
          :rank, :schur, :svd, :svdvals, :tr, :transpose, :tril, :tril!, :triu, :triu!)
   @eval $F(x::M) where {T<:AbstractFinite, M<:Matrix{T}} = T.($F(float(T).(x)))
end

for F in (:adjoint, :expm, :exmp!, :logdet, :norm, :transpose)
   @eval $F(x::A) where {T<:AbstractFinite, A<:AbstractArray{T}} = T.($F(float(T).(x)))
end

for F in (:adjoint!, :copyto!, :dot, :eigen, :eigvals, :eigvecs, :expm, :expm!,
          :fill!, :kron, :qr, :schur, :svd, :svdvals, :transpose!)
    @eval $F(x::M, y::M) where {T<:AbstractFinite, M<:AbstractMatrix{T}} = T.($F(float(T).(x), float(T).(y)))
end

#=
stack overflow if used

for F in (:copyto!, :cross, :dot, :expm, :expm!, :fill!, :kron)
    @eval $F(x::V, y::V) where {T<:AbstractFinite, V<:AbstractVector{T}} = T.($F(float(T).(x), float(T).(y)))
end


=#
