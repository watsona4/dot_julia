import DifferentialDynamicsModels: SteeringBVP, propagate, state_dim, control_dim

export SimpleCarDynamics
export SE2State, SE2vState, SE2κState, SE2vκState
export VelocityCurvatureControl, AccelerationCurvatureControl, VelocityCurvRateControl, AccelerationCurvRateControl
export VelocityCurvatureStep, VelocityCurvRateStep
export DubinsSteering, ReedsSheppSteering, DubinsCCSteering

# Simple Car Dynamics (with integrators in speed v and curvature κ)
struct SimpleCarDynamics{Dv,Dκ} <: DifferentialDynamics end

state_dim(::SimpleCarDynamics{Dv,Dκ}) where {Dv,Dκ} = Dv + Dκ + 3
control_dim(::SimpleCarDynamics{Dv,Dκ}) where {Dv,Dκ} = 2

@maintain_type struct SE2State{T}   <: FieldVector{3,T} x::T; y::T; θ::T end
@maintain_type struct SE2vState{T}  <: FieldVector{4,T} x::T; y::T; θ::T; v::T end
@maintain_type struct SE2κState{T}  <: FieldVector{4,T} x::T; y::T; θ::T; κ::T end
@maintain_type struct SE2vκState{T} <: FieldVector{5,T} x::T; y::T; θ::T; v::T; κ::T end

@maintain_type struct VelocityCurvatureControl{T}     <: FieldVector{2,T}; v::T; κ::T end
@maintain_type struct AccelerationCurvatureControl{T} <: FieldVector{2,T}; a::T; κ::T end
@maintain_type struct VelocityCurvRateControl{T}      <: FieldVector{2,T}; v::T; σ::T end
@maintain_type struct AccelerationCurvRateControl{T}  <: FieldVector{2,T}; a::T; σ::T end

const VelocityCurvatureStep{T} = StepControl{2,T,VelocityCurvatureControl{T}}    # alias used for dubins, reedsshepp
const VelocityCurvRateStep{T} = StepControl{2,T,VelocityCurvRateControl{T}}      # alias used for dubinsCC, elementary

# Dv = 0, Dκ = 0 (Dubins Car, Reeds-Shepp Car)
(::SimpleCarDynamics{0,0})((x, y, θ)::StaticVector{3}, (v, κ)::StaticVector{2}) = SVector(v*cos(θ), v*sin(θ), v*κ)
function propagate(f::SimpleCarDynamics{0,0}, q::StaticVector{3,X}, c::StepControl{2,U}) where {X,U}
    t, v, κ = c.t, c.u[1], c.u[2]
    x, y, θ = q[1], q[2], q[3]
    T = promote_type(X, U)
    s, c = sincos(θ)
    if abs(κ) > sqrt(eps(T))
        st, ct = sincos(θ + v*κ*t)
        similar_type(q, T)(x + (st - s)/κ,
                           y + (c - ct)/κ,
                           mod2piF(θ + v*κ*t))
    else
        similar_type(q, T)(x + v*c*t - v*v*s*κ*t*t/2,
                           y + v*s*t + v*v*c*κ*t*t/2,
                           mod2piF(θ + v*κ*t))
    end
end

# Dv = 1, Dκ = 0 (Dubins Car, Reeds-Shepp Car with Acceleration)
(::SimpleCarDynamics{1,0})((x, y, θ, v)::StaticVector{4}, (a, κ)::StaticVector{2}) = SVector(v*cos(θ), v*sin(θ), v*κ, a)
function propagate(f::SimpleCarDynamics{1,0}, q::StaticVector{4,X}, c::StepControl{2,U}) where {X,U}
    t, a, κ = c.t, c.u[1], c.u[2]
    x, y, θ, v = q[1], q[2], q[3], q[4]
    T = promote_type(X, U)
    s = v*t + a*t*t/2
    xyθ = propagate(SimpleCarDynamics{0,0}(), SE2State(x, y, θ), StepControl(s, VelocityCurvatureControl(T(1), κ)))
    similar_type(q, T)(xyθ[1], xyθ[2], xyθ[3], v + a*t)
end

# Dv = 0, Dκ = 1 (Continuous Curvature Car)
(::SimpleCarDynamics{0,1})((x, y, θ, κ)::StaticVector{4}, (v, σ)::StaticVector{2}) = SVector(v*cos(θ), v*sin(θ), v*κ, σ)
function propagate(f::SimpleCarDynamics{0,1}, q::StaticVector{4,X}, c::StepControl{2,U}) where {X,U}
    t, v, σ = c.t, c.u[1], c.u[2]
    x, y, θ, κ = q[1], q[2], q[3], q[4]
    T = promote_type(X, U)
    if abs(σ) > sqrt(eps(T))
        spi = sqrt(T(pi))
        θ_ = θ - v*κ*κ/σ/2
        s, c = sincos(θ_)
        sv_σ = sqrt(abs(v/σ))
        PK = sv_σ*κ/spi
        PT = sv_σ*σ*t/spi
        FCK = flipsign(flipsign(fresnelC(PK), σ), v)
        FCT = flipsign(flipsign(fresnelC(PK + PT), σ), v)
        FSK = fresnelS(PK)
        FST = fresnelS(PK + PT)
        similar_type(q, T)(x + spi*sv_σ*(c*(FCT-FCK) + s*(FSK-FST)),
                           y + spi*sv_σ*(c*(FST-FSK) + s*(FCT-FCK)),
                           mod2piF(θ + v*κ*t + v*σ*t*t/2),
                           κ + σ*t)
    elseif abs(κ) > sqrt(eps(T))
        s, c = sincos(θ)
        st, ct = sincos(θ + v*κ*t)
        similar_type(q, T)(x + (st - s)/κ,    # perhaps include higher order σ terms
                           y + (c - ct)/κ,
                           mod2piF(θ + v*κ*t + v*σ*t*t/2),
                           κ + σ*t)
    else
        s, c = sincos(θ)
        similar_type(q, T)(x + v*c*t,         # perhaps include higher order κ, σ terms
                           y + v*s*t,
                           mod2piF(θ + v*κ*t + v*σ*t*t/2),
                           κ + σ*t)
    end
end

# General Simple Car Dynamics
(::SimpleCarDynamics{1,1})((x, y, θ, v, κ)::StaticVector{5}, (a, σ)::StaticVector{2}) = SVector(v*cos(θ), v*sin(θ), v*κ, a, σ)
@generated function (::SimpleCarDynamics{Dv,Dκ})(q::StaticVector{N}, u::StaticVector{2}) where {Dv,Dκ,N}
    @assert Dv + Dκ + 3 == N
    θ = :(q[3])
    v = :(q[4])
    κ = :(q[$(4+Dv)])
    qdot = [:($v*cos($θ)); :($v*sin($θ)); :($v*$κ);
            [:(q[$(4+i)]) for i in 1:Dv-1]; :(u[1]);
            [:(q[$(4+Dv+i)]) for i in 1:Dκ-1]; :(u[2])]
    :(SVector{N}(tuple($(qdot...))))
end

# Steering
struct DubinsConstraints{T} <: SteeringConstraints
    v_max::T
    r::T
end
struct ReedsSheppConstraints{T} <: SteeringConstraints
    v_max::T
    r::T
end
struct DubinsCCConstraints{T} <: SteeringConstraints
    v_max::T
    κ_max::T
    σ_max::T
end
const DubinsSteering{T} = SteeringBVP{SimpleCarDynamics{0,0},Time,DubinsConstraints{T}}
const ReedsSheppSteering{T} = SteeringBVP{SimpleCarDynamics{0,0},Time,ReedsSheppConstraints{T}}
const DubinsCCSteering{T} = SteeringBVP{SimpleCarDynamics{0,1},Time,DubinsCCConstraints{T}}
DubinsSteering(; v=1, r=1) = SteeringBVP(SimpleCarDynamics{0,0}(), Time(), constraints=DubinsConstraints(promote(v, r)...))
ReedsSheppSteering(; v=1, r=1) = SteeringBVP(SimpleCarDynamics{0,0}(), Time(), constraints=ReedsSheppConstraints(promote(v, r)...))
DubinsCCSteering(; v=1, κ_max=1, σ_max=1) = SteeringBVP(SimpleCarDynamics{0,1}(), Time(), constraints=DubinsCCConstraints(promote(v, κ_max, σ_max)...))
function (bvp::DubinsSteering)(q0::StaticVector{3}, qf::StaticVector{3})
    dubins(q0, qf, v=bvp.constraints.v_max, r=bvp.constraints.r)
end
function (bvp::ReedsSheppSteering)(q0::StaticVector{3}, qf::StaticVector{3})
    reedsshepp(q0, qf, v=bvp.constraints.v_max, r=bvp.constraints.r)
end
function (bvp::DubinsCCSteering)(q0::StaticVector{4}, qf::StaticVector{4})
    dubinsCC(q0, qf, v=bvp.constraints.v_max, κ_max=bvp.constraints.κ_max, σ_max=bvp.constraints.σ_max)
end

## Common Steering Utilities
@inline scaleradius(c::VelocityCurvatureStep, α) = StepControl(c.t*α, VelocityCurvatureControl(c.u.v, c.u.κ/α))
@inline scalespeed(c::VelocityCurvatureStep, λ)  = StepControl(c.t/λ, VelocityCurvatureControl(c.u.v*λ, c.u.κ))
@inline scalespeed(c::VelocityCurvRateStep, λ)   = StepControl(c.t/λ, c.u*λ)
@inline carsegment2stepcontrol(t::Int, d::T) where {T} = StepControl(abs(d), VelocityCurvatureControl(T(sign(d)), T(t)))
@inline timeflip(c::VelocityCurvatureStep) = StepControl(c.t, VelocityCurvatureControl(-c.u.v, c.u.κ))
@inline reflect(c::VelocityCurvatureStep)  = StepControl(c.t, VelocityCurvatureControl(c.u.v, -c.u.κ))
@inline reverse(ctrl::StaticVector{5}) = ctrl[SVector(5,4,3,2,1)]    # TODO: implement reverse in StaticArrays

SE2State(q::StaticVector{4}) = SE2State(q[1], q[2], q[3])
SE2κState(q::StaticVector{3,T}) where {T} = SE2κState(q[1], q[2], q[3], T(0))
