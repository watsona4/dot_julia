export elementary, bi_elementary
export elementary_waypoints, bi_elementary_waypoints

function elementary((x0, y0, θ0)::StaticVector{3,T0}, (xf, yf, θf)::StaticVector{3,Tf}; v=1, λ=1//2) where {T0,Tf}
    ψ=atan(yf - y0, xf - x0)
    @assert adiff(ψ, θ0) ≈ adiff(θf, ψ) "$((x0, y0, θ0)) and $((xf, yf, θf)) are not symmetric for elementary path"
    @assert abs(adiff(ψ, θ0)) < π/2     "$((xf, yf, θf)) is not in front of $((x0, y0, θ0)) for elementary path"
    T = promote_type(T0, Tf)
    α = adiff(θf, θ0)
    d = hypot(xf - x0, yf - y0)
    α ≈ 0 && return (cost=d/v, controls=SVector(zero(VelocityCurvRateStep{T}),
                                                VelocityCurvRateStep{T}(d/v, VelocityCurvRateControl{T}(v, 0)),
                                                zero(VelocityCurvRateStep{T})))
    L = d/D(α, λ)
    σ = 4*α/(L*L*(1 - λ*λ))
    ctrl = SVector(VelocityCurvRateStep{T}(L*(1 - λ)/2, VelocityCurvRateControl{T}(1, σ)),
                   VelocityCurvRateStep{T}(L*λ, VelocityCurvRateControl{T}(1, 0)),
                   VelocityCurvRateStep{T}(L*(1 - λ)/2, VelocityCurvRateControl{T}(1, -σ)))
    (cost=L/v, controls=scalespeed.(ctrl, v))
end

function bi_elementary(q0::StaticVector{3,T0}, qf::StaticVector{3,Tf}; v=1, γ=1//2, λ=1//2) where {T0,Tf}
    T = promote_type(T0, Tf)
    x0, y0, θ0 = q0
    xf, yf, θf = qf
    @assert adiff(θ0, θf) ≈ 0 "angles of $q0 and $qf must be equal for bi-elementary path"
    q0 ≈ qf && return (cost=T(0), controls=zeros(SVector{6,VelocityCurvRateStep{T}}))
    dx = xf - x0
    dy = yf - y0
    ψ  = atan(dy, dx)
    θi = mod2piF(2*ψ - θ0)
    qi = SE2State(x0 + γ*dx, y0 + γ*dy, θi)
    ctrl = [elementary(q0, qi, v=v, λ=λ).controls; elementary(qi, qf, v=v, λ=λ).controls]
    (cost=duration(ctrl), controls=ctrl)
end

function elementary_waypoints(q0::StaticVector, qf::StaticVector, dt_or_N; v=1, λ=1//2)
    waypoints(SimpleCarDynamics{0,1}(), SE2κState(q0), elementary(q0, qf, v=v, λ=λ).controls, dt_or_N)
end

function bi_elementary_waypoints(q0::StaticVector, qf::StaticVector, dt_or_N; v=1, γ=1//2, λ=1//2)
    waypoints(SimpleCarDynamics{0,1}(), SE2κState(q0), bi_elementary(q0, qf, v=v, γ=γ, λ=λ).controls, dt_or_N)
end

@inline function D(α::T, λ) where {T}
    α = abs(α)
    c = α/(1 + λ)
    s = sqrt(α/(T(π)*(1 - λ*λ)))
    sin(c*λ)/c + (cos(α/2)*fresnelC(s*(1 - λ)) + sin(α/2)*fresnelS(s*(1 - λ)))/s
end
