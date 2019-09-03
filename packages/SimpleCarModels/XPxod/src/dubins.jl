export dubins, dubins_length, dubins_waypoints

dubins_length(q0::StaticVector{3}, qf::StaticVector{3}; r=1) = dubins(q0, qf, r=r).cost
function dubins_waypoints(q0::StaticVector{3}, qf::StaticVector{3}, dt_or_N; v=1, r=1)
    waypoints(SimpleCarDynamics{0,0}(), SE2State(q0), dubins(q0, qf, v=v, r=r).controls, dt_or_N)
end

function dubins((x0, y0, θ0)::StaticVector{3,T0}, (xf, yf, θf)::StaticVector{3,Tf}; v=1, r::R=1) where {T0,Tf,R}
    T = promote_type(T0, Tf, R)
    dx = (xf - x0)/r
    dy = (yf - y0)/r
    d = hypot(dx, dy)
    θ = atan(dy, dx)
    a = θ0 - θ
    b = θf - θ
    sa, ca = sincos(a)
    sb, cb = sincos(b)

    cmin = T(Inf)
    # LSL
    tmp = 2 + d*d - 2*(ca*cb + sa*sb - d*(sa - sb))
    if tmp >= 0
        θ = atan(cb - ca, d + sa - sb)
        t = mod2piF(-a + θ)
        p = sqrt(max(tmp, 0))
        q = mod2piF(b - θ)
        c = t + p + q

        cmin = c
        ctrl = SVector(
            carsegment2stepcontrol(1, t),
            carsegment2stepcontrol(0, p),
            carsegment2stepcontrol(1, q)
        )
    end

    # RSR
    tmp = 2 + d*d - 2*(ca*cb + sa*sb - d*(sb - sa))
    if tmp >= 0
        θ = atan(ca - cb, d - sa + sb)
        t = mod2piF(a - θ)
        p = sqrt(max(tmp, 0))
        q = mod2piF(-b + θ)
        c = t + p + q
        if c < cmin
            cmin = c
            ctrl = SVector(
                carsegment2stepcontrol(-1, t),
                carsegment2stepcontrol( 0, p),
                carsegment2stepcontrol(-1, q)
            )
        end
    end

    # RSL
    tmp = d*d - 2 + 2*(ca*cb + sa*sb - d*(sa + sb))
    if tmp >= 0
        p = sqrt(max(tmp, 0))
        θ = atan(ca + cb, d - sa - sb) - atan(T(2), p)
        t = mod2piF(a - θ)
        q = mod2piF(b - θ)
        c = t + p + q
        if c < cmin
            cmin = c
            ctrl = SVector(
                carsegment2stepcontrol(-1, t),
                carsegment2stepcontrol( 0, p),
                carsegment2stepcontrol( 1, q)
            )
        end
    end

    # LSR
    tmp = -2 + d*d + 2*(ca*cb + sa*sb + d*(sa + sb))
    if tmp >= 0
        p = sqrt(max(tmp, 0))
        θ = atan(-ca - cb, d + sa + sb) - atan(-T(2), p)
        t = mod2piF(-a + θ)
        q = mod2piF(-b + θ)
        c = t + p + q
        if c < cmin
            cmin = c
            ctrl = SVector(
                carsegment2stepcontrol( 1, t),
                carsegment2stepcontrol( 0, p),
                carsegment2stepcontrol(-1, q)
            )
        end
    end

    # RLR
    tmp = (6 - d*d  + 2*(ca*cb + sa*sb + d*(sa - sb)))/8
    if abs(tmp) < 1
        p = 2*T(pi) - acos(tmp)
        θ = atan(ca - cb, d - sa + sb)
        t = mod2piF(a - θ + p/2)
        q = mod2piF(a - b - t + p)
        c = t + p + q
        if c < cmin
            cmin = c
            ctrl = SVector(
                carsegment2stepcontrol(-1, t),
                carsegment2stepcontrol( 1, p),
                carsegment2stepcontrol(-1, q)
            )
        end
    end

    # LRL
    tmp = (6 - d*d  + 2*(ca*cb + sa*sb - d*(sa - sb)))/8
    if abs(tmp) < 1
        p = 2*T(pi) - acos(tmp)
        θ = atan(-ca + cb, d + sa - sb)
        t = mod2piF(-a + θ + p/2)
        q = mod2piF(b - a - t + p)
        c = t + p + q
        if c < cmin
            cmin = c
            ctrl = SVector(
                carsegment2stepcontrol( 1, t),
                carsegment2stepcontrol(-1, p),
                carsegment2stepcontrol( 1, q)
            )
        end
    end

    ctrl = scalespeed.(scaleradius.(ctrl, r), v)
    (cost=cmin*r/v, controls=ctrl)
end
