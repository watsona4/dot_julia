## Diagonostic code
##
import LinearAlgebra: diagm

## create a rotation matrix
function rotm(a::T,b, i, N) where {T}
    r = matrix{T}(I, N,  N)
    r[i:i+1, i:i+1] = [a -conj(b); b conj(a)]
    r
end


## make a rotator into a full matrix
function as_full(a::AbstractRotator{T}, N::Int) where {T}
    c,s = vals(a)
    i = idx(a)
    i < N || error("$i >= $N; too big")
    A = Matrix{Complex{T}}(I, N, N)
    A[i:i+1, i:i+1] = [c -conj(s); s conj(c)]
    A
end


# make zeros zeros
function zero_out!(A::Array{T}, tol=1e-12) where {T}
    A[norm.(A) .<= tol] = zero(T)
end

function zero_out!(A::Array{Complex{T}}, tol=1e-12) where {T}
    for i in eachindex(A)
        c = A[i]
        cr, ci = real(c), imag(c)
        if abs(cr) < tol
            cr = zero(T)
        end
        if abs(ci) < tol
            ci = zero(T)
        end
        A[i] = complex(cr, ci)
    end
end

## diagnostic

## create Full matrix from state object. For diagnostic purposes.
# we may or may not have a diagonal matrix to keep track or
D_matrix(state::FactorizationType{T, Val{:SingleShift}, P, Tw}) where {T,P,Tw} = diagm(0 => state.D)
D_matrix(state::FactorizationType) = diagm(0 => ones(state.N+1))#I

## We can compute yt from the decomposition of R into: R = Ct *(B + yt e1) by multiplying on left by e_n+1^T...
function _compute_yt(Cts, Bs, N, T)
    Ct = as_full(Cts[1], N+1); for i in 2:N Ct =  as_full(Cts[i],N+1)*Ct end
    B = as_full(Bs[1],N+1); for i in 2:N B = B * as_full(Bs[i],N+1) end
    e1 = zeros(T, N+1); e1[1]=one(T)
    en = zeros(T, N+1); en[N] = one(T)
    en1 = zeros(T, N+1); en1[N+1] = one(T)

    rho = transpose(en1) * Ct * e1  # scalar
    yt = -1/rho * transpose(en1)  * Ct * B
    # clean
    for i in eachindex(yt)
        if norm(yt[i]) < 1e-12
            yt[i] = 0
        end
    end

    Ct, B, yt
end

function _compute_R(Ct, B, yt, N, T)
    ## we have R = Z + x = Ct * (B  + e1 * yt)
    Z = Ct * B
    zero_out!(Z)

    e1 = zeros(T, N+1); e1[1]=one(T)
    x = Ct * e1 * yt

    R = (Z + x)
    zero_out!(R)
    R
end

function _compute_R(Ct, B, yt, D, N, T)
    ## we have R = Z + x = Ct * (B * D + e1 * yt)
    Z = Ct * B
    zero_out!(Z)

    e1 = zeros(T, N+1); e1[1]=one(T)
    x = Ct * e1 * yt
    R = Z + x
    R = diagm(0 => diag(D)) * R
    zero_out!(R)
    R
end

function compute_R(Cts, Bs, N, T)
    Ct, B, yt = _compute_yt(Cts, Bs, N, T)
    R = _compute_R(Ct, B, yt, N, T)
    R
end

function compute_R(Cts, Bs, D, N, T)
    Ct, B, yt = _compute_yt(Cts, Bs, N, T)
    R = _compute_R(Ct, B, yt, D, N, T)
    R
end

# Go from efficiently stored state to full matrix
function full_matrix(state::FactorizationType{T, St, Val{:NoPencil}, Val{:NotTwisted}}, what=:A) where {T, St}
    N = state.N
    Q = as_full(state.Q[1],N+1); for i in 2:N Q = Q * as_full(state.Q[i],N+1) end
    D = D_matrix(state)

    Ct, B, yt = _compute_yt(state.Ct, state.B, N, T)
    R = _compute_R(Ct, B, yt, D, N, T)

    what == :R && return R

    A = Q * R
    zero_out!(A)
    A
end


function full_matrix(state::FactorizationType{T, St, Val{:HasPencil}, Val{:NotTwisted}}, what=:A) where {T, St}
    n = state.N

    Q = (prod(as_full.(state.Q, n+1)))[1:n, 1:n]
    P = diagm(0 => ones(n+1))[:, 1:n]
    if St == Val{:SingleShift}
        V = P' * compute_R(state.Ct, state.B, state.D, state.N, T) * P
        W = P' * compute_R(state.Ct1, state.B1, state.D1, state.N, T) * P
    else
        V = P' * compute_R(state.Ct, state.B, state.N, T) * P
        W = P' * compute_R(state.Ct1, state.B1, state.N, T) * P
    end

    Q * V * inv(W)
end


# simple graphic to show march of algorithm
function show_status(state::FactorizationType)
    qs = [norm(u.s) for u in state.Q[state.ctrs.start_index:state.ctrs.stop_index]]
    minq = length(qs) > 0 ?  minimum(qs) : 0.0


    x = fill(".", state.N+2)
    x[state.ctrs.zero_index+1] = "α"
    x[state.ctrs.start_index+1] = "x"
    x[state.ctrs.stop_index+2] = "Δ"
    println(join(x, ""), " ($minq)")
end
