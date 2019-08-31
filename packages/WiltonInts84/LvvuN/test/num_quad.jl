using FastGaussQuadrature

function nearlyequal(x::T,y::T,τ::U) where {T,U}
    X = norm(x)
    Y = norm(y)
    D = norm(x-y)

    x == y && return true

    (X <= τ && Y <= τ) && return true
    2 * D / (X+Y) < τ
end

function legendreq(n,a,b)
    x,w = FastGaussQuadrature.gausslegendre(n)
    w *= (b-a)/2
    x = a.+(x.+1).*(b-a)/2
    return x, w
end

function dblquadints1(v1,v2,v3,x,::Type{Val{N}},ri=-1.0,ro=1.0e15) where N
    G = 10000
    s, w = legendreq(G, 0.0, 1.0)
    t1 = v1-v3
    t2 = v2-v3
    n = cross(t1,t2)
    I = zeros(eltype(x),N+3)
    K = zeros(typeof(x),N+3)
    a2 = norm(n)
    a2 < eps(eltype(x)) && return I, K
    n = normalize(n)
    d = dot(x-v1,n)
    ξ = x - d*n
    for g in 1:G
        u = s[g]
        for h in 1:G
            v = (1-u)*s[h]
            y = v3 + u*t1 + v*t2
            R = norm(x-y)
            (ri <= R <= ro) || continue
            j = a2 * w[g] * w[h] * (1-u)
            I[1] += j * d / R^3
            K[1] += j * (y-ξ) / R^3
            for n = -1 : N
                I[n+3] += j * R^n
                K[n+3] += j * (y-ξ) * R^n
            end
        end
    end
    return I, K
end
