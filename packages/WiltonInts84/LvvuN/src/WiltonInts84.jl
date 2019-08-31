module WiltonInts84

using LinearAlgebra

export contour, wiltonints

include("contour.jl")

@generated function segintsg(a, b, p, h, m, ::Type{Val{N}}) where N

    @assert N >= 0
    N3 = N +3

    xp = quote

        T = typeof(a)
        z = zero(T)
        ϵ = eps(T) * 1_000

        h2, d = h^2, abs(h)
        q2 = p^2+h2
        ra, rb = sqrt(a^2+q2), sqrt(b^2+q2)

        # n = -3
        sgn = d < ϵ ? zero(T) : sign(h)
        I1 = abs(p) < ϵ ? z : sgn*(atan((p*b)/(q2+d*rb)) - atan((p*a)/(q2 + d*ra)))
        #j = (q2 < ϵ^2) ? (b > 0 ? log(b/a) : log(a/b)) : log(b + rb) - log(a + ra)
        b2 = b^2
        if b < 0 && q2 < b2 * (0.5e-3)^2
            a2 = a^2
            j = log(a/b) + log((1-(q2/b2)/2) / (1-(q2/a2)/2))
        else
            j = log(b + rb) - log(a + ra)
        end
        J = (j,z)
        K1 = -j

        j = z
        J = (j,J[1])

        # n = -1
        I2 = p*J[2] - h*I1
        j = (b*rb - a*ra + q2*J[2])/2
        J = (j,J[1])
        K2 = j

        # n = 0
        I3 = (b*p - a*p)/2
        j = ((b*(b^2+q2)+2*q2*b) - (a*(a^2+q2)+2*q2*a))/3
        J = (j,J[1])
        K3 = j/2

    end

    for i in 4 : N3
        Ip = Symbol(:I,i-2)
        In = Symbol(:I,i)
        Kn = Symbol(:K,i)
        it = quote
            n = $i - 3
            $In = p/(n+2)*J[2] + n/(n+2)*h2*$Ip
            j = (b*rb^(n+2) - a*ra^(n+2) + (n+2)*q2*J[2])/(n+3)
            J = (j,J[1])
            $Kn = j/(n+2)
        end
        append!(xp.args, it.args)
    end

    xpi = Expr(:tuple)
    xpk = Expr(:tuple)
    for i in 1 : N3
        push!(xpi.args, Symbol(:I,i))
        push!(xpk.args, Symbol(:K,i))
    end

    push!(xp.args, :($xpi, $xpk))
    return xp
end


@generated function arcintsg(α, m, p, h, ::Type{Val{N}}) where N

    xp = quote
        T = typeof(h)
        P = typeof(m)

        h2 = h^2
        p2 = p^2
        q2 = h2 + p2
        q = sqrt(q2)
        d = sqrt(h2)

        # n == -3
        sgn = norm(h) < eps(T)*1e3 ? zero(T) : sign(h)
        I1 = -α * (h/q - sgn)
        K1 = -p / q * m

        # n == -1
        I2 = α * (q - d)
        K2 = p * q * m

        # n == 0
        I3 = α * p2 / 2
        K3 = p * q2 / 2 * m
    end

    for i in 4 : N+3
        Ip = Symbol(:I,i-2)
        In = Symbol(:I,i)
        Kn = Symbol(:K,i)
        b = quote
            n = $i - 3
            #$In = α * ((n*$Ip/α + d^n)*q2 - d^(n+2)) / (n+2)
            $In = ((n*$Ip + α * d^n)*q2 - α * d^(n+2)) / (n+2)
            $Kn = p * q^(n+2) * m / (n+2)
        end
        append!(xp.args, b.args)
    end

    xpi = Expr(:tuple, [Symbol(:I,i) for i in 1:N+3]...)
    xpk = Expr(:tuple, [Symbol(:K,i) for i in 1:N+3]...)
    push!(xp.args, :($xpi, $xpk))
    return xp
end


@generated function circleintsg(σ, p, h, ::Type{Val{N}}) where N

    xp = quote

        T = typeof(h)

        d = norm(h)
        h2 = h^2
        p2 = p^2
        q2 = h2 + p2
        q = sqrt(q2)
        α = σ * 2π

        # n == -3
        sgn = norm(h) < eps(T)*1e3 ? zero(T) : sign(h)
        I1 = -α * (h/q - sgn)

        # n == -1
        I2 = α * (q - d)

        # n == 0
        I3 = α * p2 / 2
    end

    for i in 4 : N+3
        Ip = Symbol(:I,i-2)
        In = Symbol(:I,i)
        b = quote
            n = $i - 3
            $In = α * ((n*$Ip/α + d^n)*q2 - d^(n+2)) / (n+2)
        end
        append!(xp.args, b.args)
    end

    push!(xp.args, Expr(:tuple, [Symbol(:I,i) for i in 1:N+3]...))
    return xp
end


"""
    angle(p,q)

Returns the positive angle in [0,π] between p and q
"""
function angle(p,q)
    cs = dot(p,q) / norm(p) / norm(q)
    cs = clamp(cs, -1, +1)
    return acos(cs)
end


@generated function add(P::NTuple{N}, Q::NTuple{N}) where N
    Expr(:tuple, [:(P[$i]+Q[$i]) for i in 1:N]...)
end

@generated function add(P::NTuple{N}, Q::NTuple{N}, m) where N
    Expr(:tuple, [:(P[$i]+Q[$i]*m) for i in 1:N]...)
end

@generated function buildgrad(I::NTuple{N}, K::NTuple{N}, h, n) where N
    xp = quote
        G1 = -(K[1] - I[1]*n) # grad(1/R)
        G2 = 0 * n            # grad(1)
    end

    for i in 3:N
        j = i-1
        d = i-2
        Gi = Symbol(:G,i)
        # grad(R^(i-2))
        # push!(xp.args, :($Gi = $j*(K[$i] - h*I[$i]*n)))
        push!(xp.args, :($Gi = $d*(K[$j] - h*I[$j]*n)))
    end

    push!(xp.args, Expr(:tuple, [Symbol(:G,i) for i in 1:N]...))
    return xp
end

@generated function maketuple(T,::Type{Val{N}}) where N
    xp = quote
        z = zero(T)
    end
    push!(xp.args, Expr(:tuple, [:z for i in 1:N+3]...))
    xp
end


function wiltonints(ctr, x, UB::Type{Val{N}}) where N

    n = ctr.normal
    h = ctr.height

    ulps = 1000

    ξ = x - h*n

    I = maketuple(eltype(x), UB)
    K = maketuple(typeof(x), UB)
    G = maketuple(typeof(x), UB)

    # segments contributions
    for i in eachindex(ctr.segments)
        a = ctr.segments[i][1]
        b = ctr.segments[i][2]
        t = b - a
        t /= norm(t)
        m = cross(t, n)
        p = dot(a-ξ,m)
        sa = dot(a-ξ,t)
        sb = dot(b-ξ,t)
        P, Q = segintsg(sa, sb, p, h, m, UB)
        I = add(I, P)
        K = add(K, Q, m)
    end

    # arc contributions
    for i in eachindex(ctr.arcs)
        a = ctr.arcs[i][1]
        b = ctr.arcs[i][2]
        σ = ctr.arcs[i][3]
        p = σ > 0 ? ctr.plane_outer_radius : ctr.plane_inner_radius
        u1 = (a - ξ) / p
        u2 = σ * (n × u1)
        ξb = b - ξ
        α = dot(ξb,u2) >= 0 ? σ*angle(ξb,u1) : σ*(angle(ξb,-u1) + π)
        m = (sin(α)*u1 + σ*(1-cos(α))*u2)
        #α < eps(typeof(α))*1000 && continue
        P, Q = arcintsg(α, m, p, h, UB)
        I = add(I, P)
        K = add(K, Q)
    end

    # circle contributions
    for i in eachindex(ctr.circles)
        σ = ctr.circles[i]
        p = σ > 0 ? ctr.plane_outer_radius : ctr.plane_inner_radius
        P = circleintsg(σ, p, h, UB)
        I = add(I, P)
    end

    return I, K, buildgrad(I, K, h, n)
end

"""
    wiltonints(p1,p2,p3,x,[r,R],Val{N})

Compute potential integrals over a triangle (intersected with a spherical)
mesh. Powers of the distance up to degree `N` are computed.
"""
function wiltonints(p1,p2,p3,x,r,R,VN::Type{Val{N}}) where N
    ws = workspace(typeof(p1))
    wiltonints(p1,p2,p3,x,r,R,VN,ws)
end

function wiltonints(p1,p2,p3,x,r,R,VN::Type{Val{N}},ws) where N
    ctr = contour!(p1,p2,p3,x,r,R,ws)
    wiltonints(ctr,x,VN)
end

function wiltonints(p1,p2,p3,x,VN::Type{Val{N}}) where N
    ctr = contour(p1,p2,p3,x)
    wiltonints(ctr,x,VN)
end




end # module
