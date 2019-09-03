export reedsshepp, reedsshepp_length, reedsshepp_waypoints

reedsshepp_length(q0::StaticVector{3}, qf::StaticVector{3}; r=1) = reedsshepp(q0, qf, r=r).cost
function reedsshepp_waypoints(q0::StaticVector{3}, qf::StaticVector{3}, dt_or_N; v=1, r=1)
    waypoints(SimpleCarDynamics{0,0}(), SE2State(q0), reedsshepp(q0, qf, v=v, r=r).controls, dt_or_N)
end

const POST, POST_T, POST_R, POST_B, POST_R_T, POST_B_T, POST_B_R, POST_B_R_T = 0, 1, 2, 3, 4, 5, 6, 7

function reedsshepp((x0, y0, θ0)::StaticVector{3,T0}, (xf, yf, θf)::StaticVector{3,Tf}; v=1, r::R=1) where {T0,Tf,R}
    T = promote_type(T0, Tf, R)
    dx = (xf - x0)/r
    dy = (yf - y0)/r
    st, ct = sincos(θ0)
    target = SE2State{T}(dx*ct + dy*st, -dx*st + dy*ct, mod2piF(θf - θ0))

    tTarget   = timeflip(target)
    rTarget   = reflect(target)
    trTarget  = reflect(tTarget)
    bTarget   = backwards(target)
    btTarget  = timeflip(bTarget)
    brTarget  = reflect(bTarget)
    btrTarget = reflect(btTarget)

    c, ctrl, post = T(Inf), zeros(SVector{5,VelocityCurvatureStep{T}}), POST
    # (8.1) C S C
    b, c, ctrl = LpSpLp(target,       c, ctrl); b && (post = POST)
    b, c, ctrl = LpSpLp(tTarget,      c, ctrl); b && (post = POST_T)
    b, c, ctrl = LpSpLp(rTarget,      c, ctrl); b && (post = POST_R)
    b, c, ctrl = LpSpLp(trTarget,     c, ctrl); b && (post = POST_R_T)

    # (8.2) C S C
    b, c, ctrl = LpSpRp(target,       c, ctrl); b && (post = POST)
    b, c, ctrl = LpSpRp(tTarget,      c, ctrl); b && (post = POST_T)
    b, c, ctrl = LpSpRp(rTarget,      c, ctrl); b && (post = POST_R)
    b, c, ctrl = LpSpRp(trTarget,     c, ctrl); b && (post = POST_R_T)

    # (8.3) C|C|C
    b, c, ctrl = LpRmLp(target,       c, ctrl); b && (post = POST)
    # b, c, ctrl = LpRmLp(tTarget,      c, ctrl); b && (post = POST_T) # (redundant)
    b, c, ctrl = LpRmLp(rTarget,      c, ctrl); b && (post = POST_R)
    # b, c, ctrl = LpRmLp(trTarget,     c, ctrl); b && (post = POST_R_T) # (redundant)

    # (8.4) C|C C
    b, c, ctrl = LpRmLm(target,       c, ctrl); b && (post = POST)
    b, c, ctrl = LpRmLm(tTarget,      c, ctrl); b && (post = POST_T)
    b, c, ctrl = LpRmLm(rTarget,      c, ctrl); b && (post = POST_R)
    b, c, ctrl = LpRmLm(trTarget,     c, ctrl); b && (post = POST_R_T)
    b, c, ctrl = LpRmLm(bTarget,      c, ctrl); b && (post = POST_B)
    b, c, ctrl = LpRmLm(btTarget,     c, ctrl); b && (post = POST_B_T)
    b, c, ctrl = LpRmLm(brTarget,     c, ctrl); b && (post = POST_B_R)
    b, c, ctrl = LpRmLm(btrTarget,    c, ctrl); b && (post = POST_B_R_T)

    # (8.7) C Cu|Cu C
    b, c, ctrl = LpRpuLmuRm(target,   c, ctrl); b && (post = POST)
    b, c, ctrl = LpRpuLmuRm(tTarget,  c, ctrl); b && (post = POST_T)
    b, c, ctrl = LpRpuLmuRm(rTarget,  c, ctrl); b && (post = POST_R)
    b, c, ctrl = LpRpuLmuRm(trTarget, c, ctrl); b && (post = POST_R_T)

    # (8.8) C|Cu Cu|C
    b, c, ctrl = LpRmuLmuRp(target,   c, ctrl); b && (post = POST)
    b, c, ctrl = LpRmuLmuRp(tTarget,  c, ctrl); b && (post = POST_T)
    b, c, ctrl = LpRmuLmuRp(rTarget,  c, ctrl); b && (post = POST_R)
    b, c, ctrl = LpRmuLmuRp(trTarget, c, ctrl); b && (post = POST_R_T)

    # (8.9)
    b, c, ctrl = LpRmSmLm(target,     c, ctrl); b && (post = POST)
    b, c, ctrl = LpRmSmLm(tTarget,    c, ctrl); b && (post = POST_T)
    b, c, ctrl = LpRmSmLm(rTarget,    c, ctrl); b && (post = POST_R)
    b, c, ctrl = LpRmSmLm(trTarget,   c, ctrl); b && (post = POST_R_T)
    b, c, ctrl = LpRmSmLm(bTarget,    c, ctrl); b && (post = POST_B)
    b, c, ctrl = LpRmSmLm(btTarget,   c, ctrl); b && (post = POST_B_T)
    b, c, ctrl = LpRmSmLm(brTarget,   c, ctrl); b && (post = POST_B_R)
    b, c, ctrl = LpRmSmLm(btrTarget,  c, ctrl); b && (post = POST_B_R_T)

    # (8.10)
    b, c, ctrl = LpRmSmRm(target,     c, ctrl); b && (post = POST)
    b, c, ctrl = LpRmSmRm(tTarget,    c, ctrl); b && (post = POST_T)
    b, c, ctrl = LpRmSmRm(rTarget,    c, ctrl); b && (post = POST_R)
    b, c, ctrl = LpRmSmRm(trTarget,   c, ctrl); b && (post = POST_R_T)
    b, c, ctrl = LpRmSmRm(bTarget,    c, ctrl); b && (post = POST_B)
    b, c, ctrl = LpRmSmRm(btTarget,   c, ctrl); b && (post = POST_B_T)
    b, c, ctrl = LpRmSmRm(brTarget,   c, ctrl); b && (post = POST_B_R)
    b, c, ctrl = LpRmSmRm(btrTarget,  c, ctrl); b && (post = POST_B_R_T)

    # (8.11) C|Cpi/2 S Cpi/2|C
    b, c, ctrl = LpRmSmLmRp(target,   c, ctrl); b && (post = POST)
    b, c, ctrl = LpRmSmLmRp(tTarget,  c, ctrl); b && (post = POST_T)
    b, c, ctrl = LpRmSmLmRp(rTarget,  c, ctrl); b && (post = POST_R)
    b, c, ctrl = LpRmSmLmRp(trTarget, c, ctrl); b && (post = POST_R_T)

    ctrl = scalespeed.(scaleradius.(ctrl, r), v)
    if post == POST_T
        ctrl = timeflip.(ctrl)
    elseif post == POST_R
        ctrl = reflect.(ctrl)
    elseif post == POST_B
        ctrl = reverse(ctrl)
    elseif post == POST_R_T
        ctrl = reflect.(timeflip.(ctrl))
    elseif post == POST_B_T
        ctrl = timeflip.(ctrl)
        ctrl = reverse(ctrl)
    elseif post == POST_B_R
        ctrl = reflect.(ctrl)
        ctrl = reverse(ctrl)
    elseif post == POST_B_R_T
        ctrl = reflect.(timeflip.(ctrl))
        ctrl = reverse(ctrl)
    end
    (cost=c*r/v, controls=ctrl)
end

# Utilities (pedantic about typing to guard against problems)
@inline R(x::T, y::T) where {T} = hypot(x, y), atan(y, x)
@inline function M(t::T) where {T}
    m = mod2piF(t)
    ifelse(m > pi, m - 2*T(pi), m)
end
@inline function Tau(u::T, v::T, E::T, N::T) where {T}
    delta = u - v
    A = sin(u) - sin(delta)
    B = cos(u) - cos(delta) - 1
    r, θ = R(E*A + N*B, N*A - E*B)
    t = 2*cos(delta) - 2*cos(v) - 2*cos(u) + 3
    M(θ + ifelse(t < 0, pi, 0))
end
@inline Omega(u::T, v::T, E::T, N::T, t::T) where {T} = M(Tau(u, v, E, N) - u + v - t)
@inline timeflip(q::SE2State{T}) where {T} = SE2State(-q.x, q.y, -q.θ)
@inline reflect(q::SE2State{T}) where {T} = SE2State(q.x, -q.y, -q.θ)
@inline backwards(q::SE2State{T}) where {T} = SE2State(q.x*cos(q.θ) + q.y*sin(q.θ), q.x*sin(q.θ) - q.y*cos(q.θ), q.θ)

@inline function LpSpLp((tx, ty, tθ)::SE2State{T}, c::T, ctrl::SVector{5,VelocityCurvatureStep{T}}) where {T}
    r, θ = R(tx - sin(tθ), ty - 1 + cos(tθ))
    u = r
    t = mod2piF(θ)
    v = mod2piF(tθ - t)
    cnew = t + u + v
    c <= cnew && return false, c, ctrl
    ctrl = SVector(
        carsegment2stepcontrol(1, t),
        carsegment2stepcontrol(0, u),
        carsegment2stepcontrol(1, v),
        zero(VelocityCurvatureStep{T}),
        zero(VelocityCurvatureStep{T})
    )
    true, cnew, ctrl
end

@inline function LpSpRp((tx, ty, tθ)::SE2State{T}, c::T, ctrl::SVector{5,VelocityCurvatureStep{T}}) where {T}
    r, θ = R(tx + sin(tθ), ty - 1 - cos(tθ))
    r*r < 4 && return false, c, ctrl
    u = sqrt(r*r - 4)
    r1, θ1 = R(u, T(2))
    t = mod2piF(θ + θ1)
    v = mod2piF(t - tθ)
    cnew = t + u + v
    c <= cnew && return false, c, ctrl
    ctrl = SVector(
        carsegment2stepcontrol( 1, t),
        carsegment2stepcontrol( 0, u),
        carsegment2stepcontrol(-1, v),
        zero(VelocityCurvatureStep{T}),
        zero(VelocityCurvatureStep{T})
    )
    true, cnew, ctrl
end

@inline function LpRmLp((tx, ty, tθ)::SE2State{T}, c::T, ctrl::SVector{5,VelocityCurvatureStep{T}}) where {T}
    E = tx - sin(tθ)
    N = ty + cos(tθ) - 1
    E*E + N*N > 16 && return false, c, ctrl
    r, θ = R(E, N)
    u = acos(1 - r*r/8)
    t = mod2piF(θ - u/2 + pi)
    v = mod2piF(pi - u/2 - θ + tθ)
    u = -u
    cnew = t - u + v
    c <= cnew && return false, c, ctrl
    ctrl = SVector(
        carsegment2stepcontrol( 1, t),
        carsegment2stepcontrol(-1, u),
        carsegment2stepcontrol( 1, v),
        zero(VelocityCurvatureStep{T}),
        zero(VelocityCurvatureStep{T})
    )
    true, cnew, ctrl
end

@inline function LpRmLm((tx, ty, tθ)::SE2State{T}, c::T, ctrl::SVector{5,VelocityCurvatureStep{T}}) where {T}
    E = tx - sin(tθ)
    N = ty + cos(tθ) - 1
    E*E + N*N > 16 && return false, c, ctrl
    r, θ = R(E, N)
    u = acos(1 - r*r/8)
    t = mod2piF(θ - u/2 + pi)
    v = mod2piF(pi - u/2 - θ + tθ) - 2*T(pi)
    u = -u
    cnew = t - u - v
    c <= cnew && return false, c, ctrl
    ctrl = SVector(
        carsegment2stepcontrol( 1, t),
        carsegment2stepcontrol(-1, u),
        carsegment2stepcontrol( 1, v),
        zero(VelocityCurvatureStep{T}),
        zero(VelocityCurvatureStep{T})
    )
    true, cnew, ctrl
end

@inline function LpRpuLmuRm((tx, ty, tθ)::SE2State{T}, c::T, ctrl::SVector{5,VelocityCurvatureStep{T}}) where {T}
    E = tx + sin(tθ)
    N = ty - cos(tθ) - 1
    p = (2 + sqrt(E*E + N*N))/4
    (p < 0 || p > 1) && return false, c, ctrl
    u = acos(p)
    t = mod2piF(Tau(u, -u, E, N))
    v = mod2piF(Omega(u, -u, E, N, tθ)) - 2*T(pi)
    cnew = t + 2*u - v
    c <= cnew && return false, c, ctrl
    ctrl = SVector(
        carsegment2stepcontrol( 1, t),
        carsegment2stepcontrol(-1, u),
        carsegment2stepcontrol( 1, -u),
        carsegment2stepcontrol(-1, v),
        zero(VelocityCurvatureStep{T})
    )
    true, cnew, ctrl
end

@inline function LpRmuLmuRp((tx, ty, tθ)::SE2State{T}, c::T, ctrl::SVector{5,VelocityCurvatureStep{T}}) where {T}
    E = tx + sin(tθ)
    N = ty - cos(tθ) - 1
    p = (20 - E*E - N*N)/16
    (p < 0 || p > 1) && return false, c, ctrl
    u = -acos(p)
    t = mod2piF(Tau(u, u, E, N))
    v = mod2piF(Omega(u, u, E, N, tθ))
    cnew = t - 2*u + v
    c <= cnew && return false, c, ctrl
    ctrl = SVector(
        carsegment2stepcontrol( 1, t),
        carsegment2stepcontrol(-1, u),
        carsegment2stepcontrol( 1, u),
        carsegment2stepcontrol(-1, v),
        zero(VelocityCurvatureStep{T})
    )
    true, cnew, ctrl
end

@inline function LpRmSmLm((tx, ty, tθ)::SE2State{T}, c::T, ctrl::SVector{5,VelocityCurvatureStep{T}}) where {T}
    E = tx - sin(tθ)
    N = ty + cos(tθ) - 1
    D, β = R(E, N)
    D < 2 && return false, c, ctrl
    γ = acos(2/D)
    F = sqrt(D*D/4 - 1)
    t = mod2piF(pi + β - γ)
    u = 2 - 2*F
    u > 0 && return false, c, ctrl
    v = mod2piF(-3*T(pi)/2 + γ + tθ - β) - 2*T(pi)
    cnew = t + T(pi)/2 - u - v
    c <= cnew && return false, c, ctrl
    ctrl = SVector(
        carsegment2stepcontrol( 1, t),
        carsegment2stepcontrol(-1, -T(pi)/2),
        carsegment2stepcontrol( 0, u),
        carsegment2stepcontrol( 1, v),
        zero(VelocityCurvatureStep{T})
    )
    true, cnew, ctrl
end

@inline function LpRmSmRm((tx, ty, tθ)::SE2State{T}, c::T, ctrl::SVector{5,VelocityCurvatureStep{T}}) where {T}
    E = tx + sin(tθ)
    N = ty - cos(tθ) - 1
    D, β = R(E, N)
    D < 2 && return false, c, ctrl
    t = mod2piF(β + T(pi)/2)
    u = 2 - D
    u > 0 && return false, c, ctrl
    v = mod2piF(-T(pi) - tθ + β) - 2*T(pi)
    cnew = t + T(pi)/2 - u - v
    c <= cnew && return false, c, ctrl
    ctrl = SVector(
        carsegment2stepcontrol( 1, t),
        carsegment2stepcontrol(-1, -T(pi)/2),
        carsegment2stepcontrol( 0, u),
        carsegment2stepcontrol(-1, v),
        zero(VelocityCurvatureStep{T})
    )
    true, cnew, ctrl
end

@inline function LpRmSmLmRp((tx, ty, tθ)::SE2State{T}, c::T, ctrl::SVector{5,VelocityCurvatureStep{T}}) where {T}
    E = tx + sin(tθ)
    N = ty - cos(tθ) - 1
    D, β = R(E, N)
    D < 2 && return false, c, ctrl
    γ = acos(2/D)
    F = sqrt(D*D/4 - 1)
    t = mod2piF(pi + β - γ)
    u = 4 - 2*F
    u > 0 && return false, c, ctrl
    v = mod2piF(pi + β - tθ - γ)
    cnew = t + pi - u + v
    c <= cnew && return false, c, ctrl
    ctrl = SVector(
        carsegment2stepcontrol( 1, t),
        carsegment2stepcontrol(-1, -T(pi)/2),
        carsegment2stepcontrol( 0, u),
        carsegment2stepcontrol( 1, -T(pi)/2),
        carsegment2stepcontrol(-1, v)
    )
    true, cnew, ctrl
end
