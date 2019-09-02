# some basic linear algebra stuff missing from stdlib

using LinearAlgebra.LAPACK: BlasInt, chklapackerror, @blasfunc, liblapack
using LinearAlgebra.LAPACK: checksquare

"""
    condInfest(A,F,anorm)

computes an approximation to the condition of matrix `A` in
the infinity-norm, using factorization `F` and the precomputed
infinity norm `anorm` of `A`.
"""
function condInfest(A::StridedMatrix{T},F::Factorization{T},
                    anorm=opnorm(A,Inf)) where {T}
    γ = normInfest(F) * anorm
end

"""
    norm1est!(applyA!,applyAH!,y::Vector) => γ

Estimate the 1-norm of a linear operator `A` expressed as functions which
apply `A` and `adjoint(A)` to a vector such as `y`.

cf. N.J. Higham, SIAM J. Sci. Stat. Comp. 11, 804 (1990)
"""
function norm1est!(applyA!,applyAH!,x::AbstractVector{T}) where {T}
    n = length(x)
    RT = real(T)
    x = fill(one(T)/n,n)
    y = copy(x)
    z = similar(y)
    za = Vector{RT}(undef,n)
    asign(a::Real) = a >= zero(T) ? one(T) : -one(T)
    asign(a::Complex) = a == zero(T) ? one(T) : a / abs(a)
    γ = zero(RT)
    jprev=0
    for iter=1:5
        applyA!(y)
        z = asign.(y)
        applyAH!(z)
        za .= abs2.(z)
        zam = maximum(za)
        j = findfirst(za .== zam)
        if (iter > 1) && (zam <= za[jprev])
            γ = norm(y,1)
            break
        end
        fill!(x,zero(T))
        x[j] = one(T)
        jprev = j
    end
    v,w = x,z
    v = T.((n-1:2n-2)/(n-1))
    for j=2:2:n
        v[j] = -v[j]
    end
    vnorm = norm(v,1)
    applyA!(v)
    max(γ, norm(v,1) / vnorm)
end

function norm1est(F::Factorization{T}) where {T}
    n = size(F,1)
    y = Vector{T}(undef, n)
    norm1est!(x->ldiv!(F,x),x->ldiv!(F',x),y)
end

function normInfest(F::Factorization{T}) where {T}
    n = size(F,1)
    y = Vector{T}(undef, n)
    norm1est!(x->ldiv!(F',x), x->ldiv!(F,x), y)
end

"""
    equilibrators(A) -> R,C

compute row- and column-wise scaling vectors `R,C` for a matrix `A`
such that the absolute value of the largest element in any row or
column of `Diagonal(R)*A*Diagonal(C)` is close to unity. Designed to
reduce the condition number of the working matrix.
"""
function equilibrators(A::AbstractMatrix{T}) where {T}
    abs1(x::Real) = abs(x)
    abs1(x::Complex) = abs(real(x)) + abs(imag(x))
    m,n = size(A)
    R = zeros(T,m)
    C = zeros(T,n)
    @inbounds for j=1:n
        R .= max.(R,view(A,:,j))
    end
    @inbounds for i=1:m
        if R[i] > 0
            R[i] = T(2)^floor(Int,log2(R[i]))
        end
    end
    R .= 1 ./ R
    @inbounds for i=1:m
        C .= max.(C,R[i] * view(A,i,:))
    end
    @inbounds for j=1:n
        if C[j] > 0
            C[j] = T(2)^floor(Int,log2(C[j]))
        end
    end
    C .= 1 ./ C
    R,C
end


const BlasTypes = Union{Float32,Float64,ComplexF32,ComplexF64}
# can use LAPACK.gecon for BLAS types
function condInfest(A::StridedMatrix{T},F::Factorization{T},
                    anorm=opnorm(A,Inf)) where {T<:BlasTypes}
    1/LAPACK.gecon!('I',F.factors,anorm)
end

# can use LAPACK.geequb for BLAS types
function equilibrators(A::AbstractMatrix{T}) where {T<:BlasTypes}
    Rv, Cv, rowcond, colcond, amax = geequb(A)
    Rv,Cv
end

# but first we need to wrap it...
for (geequb, elty, relty) in
    ((:dgeequb_, :Float64, :Float64),
     (:zgeequb_, :ComplexF64, :Float64),
     (:cgeequb_, :ComplexF32, :Float32),
     (:sgeequb_, :Float32, :Float32))
    @eval begin
#=
*       SUBROUTINE DGEEQUB( M, N, A, LDA, R, C, ROWCND, COLCND, AMAX,
*                           INFO )
*
*       .. Scalar Arguments ..
*       INTEGER            INFO, LDA, M, N
*       DOUBLE PRECISION   AMAX, COLCND, ROWCND
*       ..
*       .. Array Arguments ..
*       DOUBLE PRECISION   A( LDA, * ), C( * ), R( * )
=#
        function geequb(A::AbstractMatrix{$elty})
            m,n = size(A)
            lda = max(1, stride(A,2))
            C = Vector{$relty}(undef, n)
            R = Vector{$relty}(undef, m)
            info = Ref{BlasInt}()
            rowcond = Ref{$relty}()
            colcond = Ref{$relty}()
            amax = Ref{$relty}()
            ccall((@blasfunc($geequb), liblapack), Cvoid,
                  (Ref{BlasInt}, Ref{BlasInt}, Ptr{$elty}, Ref{BlasInt},
                   Ptr{$relty}, Ptr{$relty},
                   Ptr{$relty}, Ptr{$relty}, Ptr{$relty},
                   Ptr{BlasInt}),
                  m, n, A, lda, R, C, rowcond, colcond, amax, info)
            chklapackerror(info[])
            R, C, rowcond, colcond, amax
        end
    end
end
