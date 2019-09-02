module LinearDynamicsModels

using LinearAlgebra
using StaticArrays
using DifferentialDynamicsModels
using ForwardDiff
using Requires
using MacroTools

import DifferentialDynamicsModels: SteeringBVP
import DifferentialDynamicsModels: state_dim, control_dim, duration, propagate, instantaneous_control
export LinearDynamics, ZeroOrderHoldLinearization, FirstOrderHoldLinearization, linearize
export NIntegratorDynamics, DoubleIntegratorDynamics, TripleIntegratorDynamics
export LinearQuadraticSteering, NIntegratorSteering, DoubleIntegratorSteering, TripleIntegratorSteering

include("utils.jl")

# Continous-Time Linear Time-Invariant Systems
struct LinearDynamics{Dx,Du,TA<:StaticMatrix{Dx,Dx},TB<:StaticMatrix{Dx,Du},Tc<:StaticVector{Dx}} <: DifferentialDynamics
    A::TA
    B::TB
    c::Tc
end
Base.zero(::Type{LinearDynamics{Dx,Du,TA,TB,Tc}}) where {Dx,Du,TA,TB,Tc} = LinearDynamics(zero(TA), zero(TB), zero(Tc))

state_dim(::LinearDynamics{Dx,Du}) where {Dx,Du} = Dx
control_dim(::LinearDynamics{Dx,Du}) where {Dx,Du} = Du

(f::LinearDynamics{Dx,Du})(x::StaticVector{Dx}, u::StaticVector{Du}) where {Dx,Du} = f.A*x + f.B*u + f.c
function propagate(f::LinearDynamics{Dx,Du}, x::StaticVector{Dx}, SC::StepControl{Du}) where {Dx,Du}
    y = f.B*SC.u + f.c
    eᴬᵗ, ∫eᴬᵗy = integrate_expAt_B(f.A, y, SC.t)
    eᴬᵗ*x + ∫eᴬᵗy
end
function propagate(f::LinearDynamics{Dx,Du}, x::StaticVector{Dx}, RC::RampControl{Du}) where {Dx,Du}
    y = f.B*RC.uf + f.c
    eᴬᵗ, ∫eᴬᵗy = integrate_expAt_B(f.A, y, RC.t)
    z = f.B*(RC.u0 - RC.uf)
    _, _, ∫eᴬᵗztdt⁻¹ = integrate_expAt_Bt_dtinv(f.A, z, RC.t)
    eᴬᵗ*x + ∫eᴬᵗy + ∫eᴬᵗztdt⁻¹
end

# Discrete-Time Linear Time-Invariant Systems
include("linearization.jl")

# NIntegrators (DoubleIntegrator, TripleIntegrator, etc.)
function NIntegratorDynamics(::Val{N}, ::Val{D}, ::Type{T} = Rational{Int}) where {N,D,T}
    A = diagm(Val(D) => ones(SVector{(N-1)*D,T}))
    B = [zeros(SMatrix{(N-1)*D,D,T}); SMatrix{D,D,T}(I)]
    c = zeros(SVector{N*D,T})
    LinearDynamics(A, B, c)
end
NIntegratorDynamics(N::Int, D::Int, ::Type{T} = Rational{Int}) where {T} = NIntegratorDynamics(Val(N), Val(D), T)
DoubleIntegratorDynamics(D::Int, ::Type{T} = Rational{Int}) where {T} = NIntegratorDynamics(2, D, T)
TripleIntegratorDynamics(D::Int, ::Type{T} = Rational{Int}) where {T} = NIntegratorDynamics(3, D, T)

# TimePlusQuadraticControl BVPs
function SteeringBVP(f::LinearDynamics{Dx,Du}, j::TimePlusQuadraticControl{Du};
                     compile::Union{Val{false},Val{true}}=Val(false)) where {Dx,Du}
    compile === Val(true) ? error("Run `import SymPy` to enable SteeringBVP compilation.") :
                            SteeringBVP(f, j, EmptySteeringConstraints(), EmptySteeringCache())
end
const LinearQuadraticSteering{Dx,Du,Cache} = SteeringBVP{<:LinearDynamics{Dx,Du},<:TimePlusQuadraticControl{Du},EmptySteeringConstraints,Cache}
function LinearQuadraticSteering(A, B, c, R; compile::Union{Val{false},Val{true}}=Val(false))
    SteeringBVP(LinearDynamics(A, B, c), TimePlusQuadraticControl(R), compile=compile)
end
function NIntegratorSteering(N::Int, D::Int, R=SMatrix{D,D,Rational{Int}}(I); compile::Union{Val{false},Val{true}}=Val(false))
    SteeringBVP(NIntegratorDynamics(N, D), TimePlusQuadraticControl(R), compile=compile)
end
function DoubleIntegratorSteering(D::Int, R=SMatrix{D,D,Rational{Int}}(I); compile::Union{Val{false},Val{true}}=Val(false))
    SteeringBVP(DoubleIntegratorDynamics(D), TimePlusQuadraticControl(R), compile=compile)
end
function TripleIntegratorSteering(D::Int, R=SMatrix{D,D,Rational{Int}}(I); compile::Union{Val{false},Val{true}}=Val(false))
    SteeringBVP(TripleIntegratorDynamics(D), TimePlusQuadraticControl(R), compile=compile)
end

## Ad Hoc Steering
struct LinearQuadraticSteeringControl{Dx,Du,T,
                                      Tx0<:StaticVector{Dx},
                                      Txf<:StaticVector{Dx},
                                      Tf<:LinearDynamics{Dx,Du},
                                      Tj<:TimePlusQuadraticControl{Du},
                                      Tz<:StaticVector{Dx}} <: ControlInterval
    t::T
    x0::Tx0
    xf::Txf
    dynamics::Tf
    cost::Tj
    z::Tz
end
duration(lqsc::LinearQuadraticSteeringControl) = lqsc.t
function Base.zero(::Type{LinearQuadraticSteeringControl{Dx,Du,T,Tx0,Txf,Tf,Tj,Tz}}) where {Dx,Du,T,Tx0,Txf,Tf,Tj,Tz}
    LinearQuadraticSteeringControl(zero(T), zero(Tx0), zero(Txf), zero(Tf), zero(Tj), zero(Tz))
end
propagate(f::LinearDynamics, x::State, lqsc::LinearQuadraticSteeringControl) = (x - lqsc.x0) + lqsc.xf
function propagate(f::LinearDynamics, x::State, lqsc::LinearQuadraticSteeringControl, s::Number)
    f, j = lqsc.dynamics, lqsc.cost
    x0, A, B, c, R, z = lqsc.x0, f.A, f.B, f.c, j.R, lqsc.z
    eᴬˢ, ∫eᴬˢc = integrate_expAt_B(A, c, s)
    Gs = integrate_expAt_B_expATt(A, B*(R\B'), s)
    (x - x0) + eᴬˢ*x0 + ∫eᴬˢc + Gs*(eᴬˢ'\z)
end
function instantaneous_control(lqsc::LinearQuadraticSteeringControl, s::Number)
    A, B, R, z = lqsc.dynamics.A, lqsc.dynamics.B, lqsc.cost.R, lqsc.z
    eᴬˢ = exp(A*s)
    (R\B')*(eᴬˢ'\z)
end
function (j::TimePlusQuadraticControl)(lqsc::LinearQuadraticSteeringControl)
    @assert j == lqsc.cost
    cost(lqsc.dynamics, lqsc.cost, lqsc.x0, lqsc.xf, lqsc.t)
end

function (bvp::LinearQuadraticSteering{Dx,Du,EmptySteeringCache})(x0::StaticVector{Dx}, xf::StaticVector{Dx},
                                                                  c_max::T=eltype(x0)(1e6)) where {Dx,Du,T<:Number}    # TODO: handle c_max == Inf
    f, j = bvp.dynamics, bvp.cost
    A, B, c, R = f.A, f.B, f.c, j.R
    x0 == xf && return (cost=T(0), controls=LinearQuadraticSteeringControl(T(0), x0, xf, f, j, zeros(similar_type(typeof(c), T))))
    t = optimal_time(bvp, x0, xf, c_max)
    Q = B*(R\B')
    G = integrate_expAt_B_expATt(A, Q, t)
    eᴬᵗ, ∫eᴬᵗc = integrate_expAt_B(A, c, t)
    x̄ = eᴬᵗ*x0 + ∫eᴬᵗc
    z = eᴬᵗ'*(G\(xf - x̄))
    (cost=cost(f, j, x0, xf, t), controls=LinearQuadraticSteeringControl(t, x0, xf, f, j, z))
end

function cost(f::LinearDynamics{Dx,Du}, j::TimePlusQuadraticControl{Du},
              x0::StaticVector{Dx}, xf::StaticVector{Dx}, t) where {Dx,Du}
    A, B, c, R = f.A, f.B, f.c, j.R
    Q = B*(R\B')
    G = integrate_expAt_B_expATt(A, Q, t)
    eᴬᵗ, ∫eᴬᵗc = integrate_expAt_B(A, c, t)
    x̄ = eᴬᵗ*x0 + ∫eᴬᵗc
    t + (xf - x̄)'*(G\(xf - x̄))
end

function dcost(f::LinearDynamics{Dx,Du}, j::TimePlusQuadraticControl{Du},
               x0::StaticVector{Dx}, xf::StaticVector{Dx}, t) where {Dx,Du}
    A, B, c, R = f.A, f.B, f.c, j.R
    Q = B*(R\B')
    G = integrate_expAt_B_expATt(A, Q, t)
    eᴬᵗ, ∫eᴬᵗc = integrate_expAt_B(A, c, t)
    x̄ = eᴬᵗ*x0 + ∫eᴬᵗc
    z = eᴬᵗ'*(G\(xf - x̄))
    1 - 2*(A*x0 + c)'*z - z'*Q*z
end

function optimal_time(bvp::SteeringBVP{D,C,EmptySteeringConstraints,EmptySteeringCache},
                      x0::StaticVector{Dx},
                      xf::StaticVector{Dx},
                      t_max::T) where {Dx,Du,T<:Number,D<:LinearDynamics{Dx,Du},C<:TimePlusQuadraticControl{Du}}
    t = bisection(t -> dcost(bvp.dynamics, bvp.cost, x0, xf, t), t_max/100, t_max)
    t !== nothing ? t : golden_section(cost, t_max/100, t_max)
end

## Compiled Steering Functions (enabled by `import SymPy`; compiled `SteeringBVP`s return `BVPControl`s)
function __init__()
    @require SymPy="24249f21-da20-56a4-8eb1-6a02cf4ae2e6" include("sympy_bvp_compilation.jl")
end

end # module
