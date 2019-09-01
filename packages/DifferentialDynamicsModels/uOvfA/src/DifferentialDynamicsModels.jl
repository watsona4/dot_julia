module DifferentialDynamicsModels

using LinearAlgebra
using StaticArrays

export @maintain_type
export AbstractState, State, AbstractControl, Control, DifferentialDynamics, CostFunctional
export Time, TimePlusQuadraticControl
export ControlInterval, StepControl, RampControl, BVPControl
export SteeringBVP, SteeringConstraints, SteeringCache, EmptySteeringConstraints, EmptySteeringCache
export SingleIntegratorDynamics, BoundedControlNorm, SingleIntegratorSteering, GeometricSteering
export state_dim, control_dim, duration
export Propagate, InstantaneousControl, propagate, instantaneous_control, waypoints, waypoints_itr
export issymmetric

include("utils.jl")

# States, Controls, Dynamics, Cost Functionals, and Control Intervals
abstract type AbstractState end
const State = Union{AbstractState, AbstractVector{<:Number}}
abstract type AbstractControl end
const Control = Union{AbstractControl, AbstractVector{<:Number}}
abstract type DifferentialDynamics end
abstract type CostFunctional end
struct Time <: CostFunctional end
struct TimePlusQuadraticControl{Du,TR<:SMatrix{Du,Du}} <: CostFunctional
    R::TR
end
Base.zero(::Type{TimePlusQuadraticControl{Du,TR}}) where {Du,TR} = TimePlusQuadraticControl(zero(TR))
abstract type ControlInterval end
Base.zero(::CI) where {CI<:ControlInterval} = zero(CI)

(::Time)(c) = duration(c)
duration(cs) = sum(duration(c) for c in cs)
# (cost::CostFunctional)(cs) = sum(cost(c) for c in cs)    # JuliaLang/julia#29440
(cost::TimePlusQuadraticControl)(cs) = sum(cost(c) for c in cs)

# State/Control Sequences
include("iterators.jl")

## Propagation (state as a function of time)
propagate(f::DifferentialDynamics, x::State, cs) = foldl((x, c) -> propagate(f, x, c), cs, init=x)
propagate(f::DifferentialDynamics, x::State, cs, s::Number) = first(Propagate(f, x, cs, s))
propagate(f::DifferentialDynamics, x::State, cs, ss) = collect(Propagate(f, x, cs, ss))

## Instantaneous Controls (control as a function of time)
instantaneous_control(cs, s::Number) = first(InstantaneousControl(cs, s))
instantaneous_control(cs, ss) = collect(InstantaneousControl(cs, ss))

## Waypoints (convenience methods for state propagation)
function waypoints_itr(f::DifferentialDynamics, x::State, cs, dt::AbstractFloat)
    Propagate(f, x, cs, 0:dt:oftype(dt, duration(cs)))
end
function waypoints_itr(f::DifferentialDynamics, x::State, cs, N::Int)
    Propagate(f, x, cs, range(0, stop=duration(cs), length=N))
end
waypoints(f::DifferentialDynamics, x::State, cs, dt_or_N) = collect(waypoints_itr(f, x, cs, dt_or_N))

# Control Intervals
function propagate_ode(f::DifferentialDynamics, x::State, c::ControlInterval, s::Number=duration(c); N=10)
    s > 0 ? ode_rk4((y, t) ->  f(y, instantaneous_control(c,  t)), x,  s, zero(s), N) :
            ode_rk4((y, t) -> -f(y, instantaneous_control(c, -t)), x, -s, zero(s), N)
end
propagate(f::DifferentialDynamics, x::State, c::ControlInterval) = propagate_ode(f, x, c)    # general fallback

## Step Control
struct StepControl{N,T,S<:StaticVector{N}} <: ControlInterval
    t::T
    u::S
    function (::Type{SC})(t::T, u::S) where {N,T,S<:StaticVector{N},SC<:StepControl}
        new{N,T,S}(t, u)
    end
end
const ZeroOrderHoldControl{N,T,S} = StepControl{N,T,S}
duration(c::StepControl) = c.t
Base.zero(::Type{StepControl{N,T,S}}) where {N,T,S} = StepControl(zero(T), zero(S))
function propagate(f::DifferentialDynamics, x::State, c::StepControl, s::Number)
    s <= 0           ? x :
    s >= duration(c) ? propagate(f, x, c) :
                       propagate(f, x, StepControl(s, c.u))
end
instantaneous_control(c::StepControl, s::Number) = c.u
(cost::TimePlusQuadraticControl)(c::StepControl) = c.t*(1 + c.u'*cost.R*c.u)

## Ramp Control
struct RampControl{N,T,S0<:StaticVector{N},Sf<:StaticVector{N}} <: ControlInterval
    t::T
    u0::S0
    uf::Sf
    function (::Type{RC})(t::T, u0::S0, uf::Sf) where {N,T,S0<:StaticVector{N},Sf<:StaticVector{N},RC<:RampControl}
        new{N,T,S0,Sf}(t, u0, uf)
    end
end
const FirstOrderHoldControl{N,T,S0,Sf} = RampControl{N,T,S0,Sf}
RampControl(c::StepControl) = RampControl(c.t, c.u, c.u)
duration(c::RampControl) = c.t
Base.zero(::Type{RampControl{N,T,S0,Sf}}) where {N,T,S0,Sf} = RampControl(zero(T), zero(S0), zero(Sf))
function propagate(f::DifferentialDynamics, x::State, c::RampControl, s::Number)
    s <= 0           ? x :
    s >= duration(c) ? propagate(f, x, c) :
                       propagate(f, x, RampControl(s, c.u0, instantaneous_control(c, s)))
end
instantaneous_control(c::RampControl, s::Number) = c.u0 + (s/c.t)*(c.uf - c.u0)
(cost::TimePlusQuadraticControl)(c::RampControl) = (Δu = c.uf - c.u0; c.t*(1 + c.u0'*cost.R*c.uf + Δu'*cost.R*Δu/3))

## BVP Control
struct BVPControl{T,S0<:State,Sf<:State,Fx<:Function,Fu<:Function} <: ControlInterval
    t::T
    x0::S0
    xf::Sf
    x::Fx
    u::Fu
end
duration(c::BVPControl) = c.t
function Base.zero(::Type{BVPControl{T,S0,Sf,Fx,Fu}}) where {T,S0,Sf,Fx,Fu}
    BVPControl(zero(T), zero(S0), zero(Sf), Fx.instance, Fu.instance)
end
propagate(f::DifferentialDynamics, x::State, c::BVPControl) = (x - c.x0) + c.xf
propagate(f::DifferentialDynamics, x::State, c::BVPControl, s::Number) = (x - c.x0) + c.x(c.x0, c.xf, c.t, s)
instantaneous_control(c::BVPControl, s::Number) = c.u(c.x0, c.xf, c.t, s)
function (cost::TimePlusQuadraticControl)(c::BVPControl{T}; N=10) where {T}
    c.t + ode_rk4((y, t) -> (u = instantaneous_control(c, t); u'*cost.R*u), zero(T), c.t, zero(T), N)
end

# Steering Two-Point Boundary Value Problems (BVPs)
abstract type SteeringConstraints end
abstract type SteeringCache end
struct EmptySteeringConstraints <: SteeringConstraints end
struct BoundedControlNorm{P,T} <: SteeringConstraints
    b::T
end
BoundedControlNorm(b::T=1) where {T} = BoundedControlNorm{2,T}(b)
BoundedControlNorm{P}(b::T) where {P,T} = BoundedControlNorm{P,T}(b)
struct EmptySteeringCache <: SteeringCache end
struct SteeringBVP{D<:DifferentialDynamics,C<:CostFunctional,SC<:SteeringConstraints,SD<:SteeringCache}
    dynamics::D
    cost::C
    constraints::SC
    cache::SD
end
function SteeringBVP(dynamics::DifferentialDynamics, cost::CostFunctional;
                     constraints::SteeringConstraints=EmptySteeringConstraints(),
                     cache::SteeringCache=EmptySteeringCache())
    SteeringBVP(dynamics, cost, constraints, cache)
end
LinearAlgebra.issymmetric(bvp::SteeringBVP) = false                           # general fallback
(bvp::SteeringBVP)(x0::State, xf::State, cost_bound::Number) = bvp(x0, xf)    # general fallback

# Single Integrator
struct SingleIntegratorDynamics{N} <: DifferentialDynamics end

state_dim(::SingleIntegratorDynamics{N}) where {N} = N
control_dim(::SingleIntegratorDynamics{N}) where {N} = N

(::SingleIntegratorDynamics{N})(x::StaticVector{N}, u::StaticVector{N}) where {N} = u
propagate(f::SingleIntegratorDynamics{N}, x::StaticVector{N}, c::StepControl{N}) where {N} = x + c.t*c.u
propagate(f::SingleIntegratorDynamics{N}, x::StaticVector{N}, c::RampControl{N}) where {N} = x + c.t*(c.u0 + c.uf)/2

LinearAlgebra.issymmetric(bvp::SteeringBVP{<:SingleIntegratorDynamics,<:CostFunctional,<:BoundedControlNorm}) = true
const GeometricSteering{N,T} = SteeringBVP{SingleIntegratorDynamics{N},Time,BoundedControlNorm{2,T}}
const SingleIntegratorSteering{N,T} = GeometricSteering{N,T}
GeometricSteering{N}(b=1) where {N} = SteeringBVP(SingleIntegratorDynamics{N}(), Time(), constraints=BoundedControlNorm(b))
GeometricSteering(N, b=1) = GeometricSteering{N}(b)
function (bvp::GeometricSteering{N})(x0::StaticVector{N}, xf::StaticVector{N}) where {N}
    c = norm(xf - x0)/bvp.constraints.b
    ctrl = StepControl(c, SVector((xf - x0)*(c > 0 ? inv(c) : 0)))    # @benchmark appears faster than ifelse
    (cost=c, controls=ctrl)
end

end # module
