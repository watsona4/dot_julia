import StaticArrays: SUnitRange

# Computing Integrals Involving the Matrix Exponential (elements of Van Loan '78)
function _integrate_expAt_B(A::StaticMatrix{N,N}, B::StaticMatrix{N,M}, dt::T) where {N,M,T}
    S = promote_type(eltype(A), eltype(B), T)
    X = exp([[A B]; zeros(SMatrix{M,N+M,S})]*dt)
    (eᴬᵗ=X[SUnitRange(1,N),SUnitRange(1,N)], ∫eᴬᵗB=X[SUnitRange(1,N),SUnitRange(N+1,N+M)])
end
function integrate_expAt_B(A::StaticMatrix{N,N}, B::StaticVector{N}, dt) where {N}
    ans = _integrate_expAt_B(A, SMatrix{N,1}(B), dt)
    (eᴬᵗ=ans.eᴬᵗ, ∫eᴬᵗB=SVector(ans.∫eᴬᵗB))
end
function integrate_expAt_B(A::StaticMatrix{N,N}, B::StaticMatrix{N,M}, dt) where {N,M}
    eᴬᵗ, ∫eᴬᵗB₁ = integrate_expAt_B(A, B[:,1], dt)
    (eᴬᵗ=eᴬᵗ, ∫eᴬᵗB=hcat(∫eᴬᵗB₁, ntuple(i -> integrate_expAt_B(A, B[:,i+1], dt).∫eᴬᵗB, Val(M-1))...))
end

function _integrate_expAt_Bt_dtinv(A::StaticMatrix{N,N}, B::StaticMatrix{N,M}, dt::T) where {N,M,T}
    S = promote_type(eltype(A), eltype(B), T)
    X = exp([[A B zeros(typeof(B))]*dt;
             [zeros(SMatrix{M,N+M,S}) SMatrix{M,M,S}(I)];
             zeros(SMatrix{M,N+2*M,S})])
    ∫eᴬᵗB=X[SUnitRange(1,N),SUnitRange(N+1,N+M)]
    (eᴬᵗ=X[SUnitRange(1,N),SUnitRange(1,N)], ∫eᴬᵗB=∫eᴬᵗB, ∫eᴬᵗBtdt⁻¹=∫eᴬᵗB - X[SUnitRange(1,N),SUnitRange(N+M+1,N+2*M)])
end
function integrate_expAt_Bt_dtinv(A::StaticMatrix{N,N}, B::StaticVector{N}, dt) where {N}
    ans = _integrate_expAt_Bt_dtinv(A, SMatrix{N,1}(B), dt)
    (eᴬᵗ=ans.eᴬᵗ, ∫eᴬᵗB=SVector(ans.∫eᴬᵗB), ∫eᴬᵗBtdt⁻¹=SVector(ans.∫eᴬᵗBtdt⁻¹))
end
function integrate_expAt_Bt_dtinv(A::StaticMatrix{N,N}, B::StaticMatrix{N,M}, dt) where {N,M}
    eᴬᵗ, ∫eᴬᵗB₁, ∫eᴬᵗB₁tdt⁻¹ = integrate_expAt_Bt_dtinv(A, B[:,1], dt)
    X₁ = [∫eᴬᵗB₁; ∫eᴬᵗB₁tdt⁻¹]
    X = hcat(X₁, ntuple(i -> (ans = integrate_expAt_Bt_dtinv(A, B[:,i+1], dt); [ans.∫eᴬᵗB; ans.∫eᴬᵗBtdt⁻¹]), Val(M-1))...)
    (eᴬᵗ=eᴬᵗ, ∫eᴬᵗB=X[SUnitRange(1,N),:], ∫eᴬᵗBtdt⁻¹=X[SUnitRange(N+1,2*N),:])
end

function integrate_expAt_B_expATt(A::StaticMatrix{N,N}, B::StaticMatrix{N,N}, dt) where {N}
    X = exp([[-A B]; [zeros(typeof(A)) A']]*dt)
    X[SUnitRange(N+1,2*N),SUnitRange(N+1,2*N)]'*X[SUnitRange(1,N),SUnitRange(N+1,2*N)]
end

# Univariate Optimization (@inline here and in optimal_time necessary to eliminate allocations)
@inline function golden_section(f, a, b; ϵ=1e-3)
    T = typeof((a + b)/2)
    gr = T((1 + sqrt(5))/2)
    fa, fb = f(a), f(b)
    while fa < fb; a /= 2; fa = f(a); end
    m1 = b - (b - a)/gr
    m2 = a + (b - a)/gr
    while abs(m1 - m2) > ϵ
        if f(m1) < f(m2)
            b = m2
        else
            a = m1
        end
        m1 = b - (b - a)/gr
        m2 = a + (b - a)/gr
    end
    (a + b)/2
end

@inline function bisection(f, a, b; ϵ=1e-3)
    # Bisection
    # Broken for Float32 triple integrator with R = [1f-3],
    # q0 = SVector(-6.094263f0, 0.014560595f0, -0.6846263f0)
    # qf = SVector(-6.0940447f0, 0.0f0, 0.0f0)
    f(b) < 0 && return b
    fa = f(a)
    while fa > 0
        a /= 2
        fa = f(a)
        (a == 0 || isnan(fa) || isinf(fa)) && return nothing    # workaround for above
    end
    m = (a + b)/2
    fm = f(m)
    while abs(fm) > ϵ && abs(a - b) > ϵ
        fm > 0 ? b = m : a = m
        m = (a + b)/2
        fm = f(m)
    end
    m
end

@inline function false_position(f, a, b; ϵ=1e-3)
    f(b) < 0 && return b
    fa = f(a)
    while fa > 0
        a /= 2
        fa = f(a)
        (a == 0 || isnan(fa) || isinf(fa)) && return nothing
    end
    fb = f(b)
    x = (a*fb - b*fa)/(fb - fa)
    fx = f(x)
    while abs(fx) > ϵ && abs(a - b) > ϵ
        fx > 0 ? b = x : a = x
        x = (a*fb - b*fa)/(fb - fa)
        fx = f(x)
    end
    x
end

@inline function newton(f, f′, a, b; ϵ=1e-6)
    # Bisection / Newton's method combo
    f(b) < 0 && return b
    fa = f(a)
    while fa > 0
        a /= 2
        fa = f(a)
        (a == 0 || isnan(fa) || isinf(fa)) && return nothing
    end
    x = (a + b)/2
    fx = f(x)
    while abs(fx) > ϵ && abs(a - b) > ϵ
        x = x - fx / f′(x)
        (x < a || x > b) && (x = (a + b)/2)
        fx = f(x)
        fx > 0 ? b = x : a = x
    end
    x
end
