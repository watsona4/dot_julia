export dubinsCC, dubinsCC_length, dubinsCC_waypoints

dubinsCC_length(q0::StaticVector, qf::StaticVector; κ_max=1, σ_max=1) = dubinsCC(q0, qf, κ_max=κ_max, σ_max=σ_max).cost
function dubinsCC_waypoints(q0::StaticVector, qf::StaticVector, dt_or_N; v=1, κ_max=1, σ_max=1)
    waypoints(SimpleCarDynamics{0,1}(), SE2κState(q0), dubinsCC(q0, qf, v=v, κ_max=κ_max, σ_max=σ_max).controls, dt_or_N)
end

function dubinsCC(q0::StaticVector{4,T0}, qf::StaticVector{4,Tf}; v::V=1, κ_max::K=1, σ_max::S=1) where {T0,Tf,V,K,S}
    @assert (abs(q0.κ) <= κ_max && abs(qf.κ) <= κ_max) "$q0, $qf endpoint curvatures exceed bound of $κ_max"

    D = SimpleCarDynamics{0,1}()
    T = promote_type(T0, Tf, V, K, S)
    cmin, ctrl = T(Inf), zeros(SVector{11,VelocityCurvRateStep{T}})

    t0 = abs(q0.κ)/σ_max
    tf = abs(qf.κ)/σ_max
    c0_towards = StepControl{T}( t0, VelocityCurvRateControl{T}(v, -flipsign(σ_max, q0.κ)))
    c0_away    = StepControl{T}(-t0, VelocityCurvRateControl{T}(v,  flipsign(σ_max, q0.κ)))
    cf_towards = StepControl{T}( tf, VelocityCurvRateControl{T}(v, -flipsign(σ_max, qf.κ)))
    cf_away    = StepControl{T}(-tf, VelocityCurvRateControl{T}(v,  flipsign(σ_max, qf.κ)))

    # towards 0, towards 0
    q0_0 = SE2State(propagate(D, q0, c0_towards))
    qf_0 = SE2State(propagate(D, qf, cf_towards))
    cnew, ctrl_0 = dubinsCC(q0_0, qf_0, true, false, true, true, qf.κ >= 0, qf.κ <= 0, v=v, κ_max=κ_max, σ_max=σ_max)
    cnew = cnew + (t0 - tf)
    if cnew < cmin
        cmin = cnew
        ctrl_0 = setindex(ctrl_0, StepControl(ctrl_0[9].t - tf, ctrl_0[9].u), 9)
        ctrl = [SVector(c0_towards); ctrl_0; SVector(zero(VelocityCurvRateStep{T}))]
    end

    # towards 0, away from 0
    q0_0 = SE2State(propagate(D, q0, c0_towards))
    qf_0 = SE2State(propagate(D, qf, cf_away))
    cnew, ctrl_0 = dubinsCC(q0_0, qf_0, true, true, true, true, true, true, v=v, κ_max=κ_max, σ_max=σ_max)
    cnew = cnew + (t0 + tf)
    if cnew < cmin
        cmin = cnew
        ctrl = [SVector(c0_towards); ctrl_0; SVector(StepControl(tf, cf_away.u))]
    end

    # away from 0, towards 0
    q0_0 = SE2State(propagate(D, q0, c0_away))
    qf_0 = SE2State(propagate(D, qf, cf_towards))
    cnew, ctrl_0 = dubinsCC(q0_0, qf_0, false, false, q0.κ >= 0, q0.κ <= 0, qf.κ >= 0, qf.κ <= 0, v=v, κ_max=κ_max, σ_max=σ_max)
    cnew = cnew + (-t0 - tf)
    if cnew < cmin
        cmin = cnew
        ctrl_0 = setindex(ctrl_0, StepControl(ctrl_0[1].t - t0, ctrl_0[1].u), 1)
        ctrl_0 = setindex(ctrl_0, StepControl(ctrl_0[9].t - tf, ctrl_0[9].u), 9)
        ctrl = [SVector(zero(VelocityCurvRateStep{T})); ctrl_0; SVector(zero(VelocityCurvRateStep{T}))]
    end

    # away from 0, away from 0
    q0_0 = SE2State(propagate(D, q0, c0_away))
    qf_0 = SE2State(propagate(D, qf, cf_away))
    cnew, ctrl_0 = dubinsCC(q0_0, qf_0, false, true, q0.κ >= 0, q0.κ <= 0, true, true, v=v, κ_max=κ_max, σ_max=σ_max)
    cnew = cnew + (-t0 + tf)
    if cnew < cmin
        cmin = cnew
        ctrl_0 = setindex(ctrl_0, StepControl(ctrl_0[1].t - t0, ctrl_0[1].u), 1)
        ctrl = [SVector(zero(VelocityCurvRateStep{T})); ctrl_0; SVector(StepControl(tf, cf_away.u))]
    end

    (cost=cmin, controls=ctrl)
end

function dubinsCC((x0, y0, θ0)::StaticVector{3,T0},
                  (xf, yf, θf)::StaticVector{3,Tf},
                  allow_short_turn_1=true,
                  allow_short_turn_3=true,
                  LXX=true,
                  RXX=true,
                  XXL=true,
                  XXR=true;
                  v::V=1,
                  κ_max::K=1,
                  σ_max::S=1) where {T0,Tf,V,K,S}
    T = promote_type(T0, Tf, V, K, S)
    θ_lim, r, γ = CC_steering_constants(T(κ_max), T(σ_max/v))
    @inline turn_length(β) = CC_turn_length(β, T(κ_max), T(σ_max/v), θ_lim, r, γ)
    @inline turn_control(β) = CC_turn_control(β, T(κ_max), T(σ_max/v), θ_lim, r, γ)

    dx = (xf - x0)/r
    dy = (yf - y0)/r
    d = hypot(dx, dy)
    θ = atan(dy, dx)
    a = θ0 - θ
    b = θf - θ

    sap, cap = sincos(a + γ)
    sbp, cbp = sincos(b + γ)
    sam, cam = sincos(a - γ)
    sbm, cbm = sincos(b - γ)
    sγ, cγ = sincos(γ)
    cmin = T(Inf)
    ctrl = zeros(SVector{9,VelocityCurvRateStep{T}})

    ### 1. LSL: a-γ, b+γ
    if LXX && XXL
        ca, sa, cb, sb = cam, sam, cbp, sbp
        tmp = 2 + d*d - 2*(ca*cb + sa*sb - d*(sa - sb))
        if tmp >= 4*sγ*sγ    # TODO: M-style connections
            θ = atan(cb - ca, d + sa - sb)
            t = mod2piF(-a + θ)
            p = sqrt(tmp) - 2*sγ
            q = mod2piF(b - θ)
            p = r*p
            if (allow_short_turn_1 || t >= θ_lim) && (allow_short_turn_3 || q >= θ_lim)
                c = turn_length(t) + p + turn_length(q)
                if c < cmin
                    cmin = c
                    ctrl = [
                        turn_control(t);
                        SVector(zero(VelocityCurvRateStep{T}),
                                StepControl(p, VelocityCurvRateControl(T(1), T(0))),
                                zero(VelocityCurvRateStep{T}));
                        turn_control(q)
                    ]
                end
            end
        end
    end

    ### 2. RSR: a+γ, b-γ
    if RXX && XXR
        ca, sa, cb, sb = cap, sap, cbm, sbm
        tmp = 2 + d*d - 2*(ca*cb + sa*sb - d*(sb - sa))
        if tmp >= 4*sγ*sγ    # TODO: M-style connections
            θ = atan(ca - cb, d - sa + sb)
            t = mod2piF(a - θ)
            p = sqrt(tmp) - 2*sγ
            q = mod2piF(-b + θ)
            p = r*p
            if (allow_short_turn_1 || t >= θ_lim) && (allow_short_turn_3 || q >= θ_lim)
                c = turn_length(t) + p + turn_length(q)
                if c < cmin
                    cmin = c
                    ctrl = [
                        turn_control(-t);
                        SVector(zero(VelocityCurvRateStep{T}),
                                StepControl(p, VelocityCurvRateControl(T(1), T(0))),
                                zero(VelocityCurvRateStep{T}));
                        turn_control(-q)
                    ]
                end
            end
        end
    end

    ### 3. RSL: a+γ, b+γ
    if RXX && XXL
        ca, sa, cb, sb = cap, sap, cbp, sbp
        tmp = d*d - 2 + 2*(ca*cb + sa*sb - d*(sa + sb))
        if tmp >= 0
            p = sqrt(tmp + 4*sγ*sγ) - 2*sγ
            x = sqrt(tmp)
            θ = atan(ca + cb, d - sa - sb) - atan(T(2), x)
            ε = acot(x/2) - acot((p/2 + sγ)/cγ)
            t = mod2piF(a - θ - ε)
            q = mod2piF(b - θ - ε)
            p = r*p
            if (allow_short_turn_1 || t >= θ_lim) && (allow_short_turn_3 || q >= θ_lim)
                c = turn_length(t) + p + turn_length(q)
                if c < cmin
                    cmin = c
                    ctrl = [
                        turn_control(-t);
                        SVector(zero(VelocityCurvRateStep{T}),
                                StepControl(p, VelocityCurvRateControl(T(1), T(0))),
                                zero(VelocityCurvRateStep{T}));
                        turn_control(q)
                    ]
                end
            end
        end
    end

    ### 4. LSR: a-γ, b-γ
    if LXX && XXR
        ca, sa, cb, sb = cam, sam, cbm, sbm
        tmp = -2 + d*d + 2*(ca*cb + sa*sb + d*(sa + sb))
        if tmp >= 0
            p = sqrt(tmp + 4*sγ*sγ) - 2*sγ
            x = sqrt(tmp)
            θ = atan(-ca - cb, d + sa + sb) - atan(-T(2), x)
            ε = acot(x/2) - acot((p/2 + sγ)/cγ)
            t = mod2piF(-a + θ - ε)
            q = mod2piF(-b + θ - ε)
            p = r*p
            if (allow_short_turn_1 || t >= θ_lim) && (allow_short_turn_3 || q >= θ_lim)
                c = turn_length(t) + p + turn_length(q)
                if c < cmin
                    cmin = c
                    ctrl = [
                        turn_control(t);
                        SVector(zero(VelocityCurvRateStep{T}),
                                StepControl(p, VelocityCurvRateControl(T(1), T(0))),
                                zero(VelocityCurvRateStep{T}));
                        turn_control(-q)
                    ]
                end
            end
        end
    end

    ### 5. RLR: a+γ, b-γ
    if RXX && XXR
        ca, sa, cb, sb = cap, sap, cbm, sbm
        tmp = (6 - d*d + 2*(ca*cb + sa*sb + d*(sa - sb)))/8
        if abs(tmp) < 1
            p_1 = mod2piF(acos(tmp) - 2*γ)
            p_2 = mod2piF(-p_1 - 4*γ)
            t_2 = mod2piF(a - atan(ca - cb, d - sa + sb) + p_2/2)
            q_2 = mod2piF(a - b - t_2 + p_2)
            t_1 = mod2piF(t_2 + T(pi) - p_2 - 2*γ)
            q_1 = mod2piF(q_2 + T(pi) - p_2 - 2*γ)
            if (allow_short_turn_1 || t_1 >= θ_lim) && (allow_short_turn_3 || q_1 >= θ_lim)
                c_1 = turn_length(t_1) + turn_length(p_1) + turn_length(q_1)
                if c_1 < cmin
                    cmin = c_1
                    ctrl = [
                        turn_control(-t_1);
                        turn_control(p_1);
                        turn_control(-q_1)
                    ]
                end
            end
            if (allow_short_turn_1 || t_2 >= θ_lim) && (allow_short_turn_3 || q_2 >= θ_lim)
                c_2 = turn_length(t_2) + turn_length(p_2) + turn_length(q_2)
                if c_2 < cmin
                    cmin = c_2
                    ctrl = [
                        turn_control(-t_2);
                        turn_control(p_2);
                        turn_control(-q_2)
                    ]
                end
            end
        end
    end

    ### 6. LRL: a-γ, b+γ
    if LXX && XXL
        ca, sa, cb, sb = cam, sam, cbp, sbp
        tmp = (6 - d*d + 2*(ca*cb + sa*sb - d*(sa - sb)))/8
        if abs(tmp) < 1
            p_1 = mod2piF(acos(tmp) - 2*γ)
            p_2 = mod2piF(-p_1 - 4*γ)
            t_2 = mod2piF(-a + atan(-ca + cb, d + sa - sb) + p_2/2)
            q_2 = mod2piF(b - a - t_2 + p_2)
            t_1 = mod2piF(t_2 + T(pi) - p_2 - 2*γ)
            q_1 = mod2piF(q_2 + T(pi) - p_2 - 2*γ)
            if (allow_short_turn_1 || t_1 >= θ_lim) && (allow_short_turn_3 || q_1 >= θ_lim)
                c_1 = turn_length(t_1) + turn_length(p_1) + turn_length(q_1)
                if c_1 < cmin
                    cmin = c_1
                    ctrl = [
                        turn_control(t_1);
                        turn_control(-p_1);
                        turn_control(q_1)
                    ]
                end
            end
            if (allow_short_turn_1 || t_2 >= θ_lim) && (allow_short_turn_3 || q_2 >= θ_lim)
                c_2 = turn_length(t_2) + turn_length(p_2) + turn_length(q_2)
                if c_2 < cmin
                    cmin = c_2
                    ctrl = [
                        turn_control(t_2);
                        turn_control(-p_2);
                        turn_control(q_2)
                    ]
                end
            end
        end
    end

    ctrl = scalespeed.(ctrl, v)
    (cost=cmin/v, controls=ctrl)
end

@inline function CC_steering_constants(κ_max::K, σ_max::S) where {K,S}
    T  = promote_type(K, S)
    xi = sqrt(T(pi)/σ_max)*fresnelC(κ_max/sqrt(T(pi)*σ_max))
    yi = sqrt(T(pi)/σ_max)*fresnelS(κ_max/sqrt(T(pi)*σ_max))
    θi = κ_max*κ_max/(2*σ_max)
    s, c = sincos(θi)
    xΩ = xi - s/κ_max
    yΩ = yi + c/κ_max
    (θ=2*θi, r=hypot(xΩ, yΩ), γ=atan(xΩ/yΩ))
end

@inline function CC_turn_length(β::T, κ_max, σ_max, θ_lim, r, γ) where {T}    # θ_lim = κ_max^2/σ_max
    b = abs(β)
    if b < sqrt(eps(T))
        2*r*sin(γ) + b*r*cos(γ)
    elseif b < θ_lim
        bp = sqrt(b/T(pi))
        σ = (cos(b/2)*fresnelC(bp) + sin(b/2)*fresnelS(bp))/r/sin(b/2 + γ)
        σ = T(pi)*σ*σ
        2*sqrt(b/σ)
    else
        (b + θ_lim)/κ_max
    end
end

@inline function CC_turn_control(β::T, κ_max, σ_max, θ_lim, r, γ) where {T}    # θ_lim = κ_max^2/σ_max
    b = abs(β)
    if b < sqrt(eps(T))
        sγ, cγ = sincos(γ)
        SVector(
            StepControl(r*sγ + b*r*cγ/2, VelocityCurvRateControl(T(1), b/(r*r*sγ*sγ))),
            zero(VelocityCurvRateStep{T}),
            StepControl(r*sγ + b*r*cγ/2, VelocityCurvRateControl(T(1), -b/(r*r*sγ*sγ)))
        )
    elseif b < θ_lim
        bp = sqrt(b/T(pi))
        σ = (cos(b/2)*fresnelC(bp) + sin(b/2)*fresnelS(bp))/r/sin(b/2 + γ)
        σ = T(pi)*σ*σ
        SVector(
            StepControl(sqrt(b/σ), VelocityCurvRateControl(T(1), flipsign(σ, β))),
            zero(VelocityCurvRateStep{T}),
            StepControl(sqrt(b/σ), VelocityCurvRateControl(T(1), -flipsign(σ, β)))
        )
    else
        SVector(
            StepControl(κ_max/σ_max, VelocityCurvRateControl(T(1), flipsign(σ_max, β))),
            StepControl((b - θ_lim)/κ_max, VelocityCurvRateControl(T(1), T(0))),
            StepControl(κ_max/σ_max, VelocityCurvRateControl(T(1), -flipsign(σ_max, β)))
        )
    end
end
