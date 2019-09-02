using LinearDynamicsModels
using DifferentialDynamicsModels
using LinearAlgebra
using StaticArrays
using Test

@maintain_type struct RoboState{T} <: FieldVector{2,T}
    x::T
    y::T
end

struct TestLinearDynamics{Dx,Du,TA<:StaticMatrix{Dx,Dx},TB<:StaticMatrix{Dx,Du},Tc<:StaticVector{Dx}} <: DifferentialDynamics
    A::TA
    B::TB
    c::Tc
end
(f::TestLinearDynamics{Dx,Du})(x::StaticVector{Dx}, u::StaticVector{Du}) where {Dx,Du} = f.A*x + f.B*u + f.c

Base.isapprox(x, y; atol=0) = all(isapprox(getfield(x, i), getfield(y, i), atol=atol) for i in 1:fieldcount(typeof(x)))

DI = DoubleIntegratorDynamics(2)
J  = TimePlusQuadraticControl(SMatrix{2,2,Rational{Int}}(I))
@test_throws ErrorException SteeringBVP(DI, J, compile=Val(true))
using SymPy
bvp_compiled = SteeringBVP(DI, J, compile=Val(true))
bvp_adhoc    = SteeringBVP(DI, J, compile=Val(false))

for T in (Float32, Float64)
    # LinearDynamics vs. Ad Hoc Single Integrator (from DifferentialDynamicsModels)
    SI_linear = NIntegratorDynamics(1, 2)
    SI_adhoc  = SingleIntegratorDynamics{2}()
    @test state_dim(SI_linear) == 2
    @test control_dim(SI_linear) == 2

    x0 = rand(RoboState{T})
    sc = StepControl(.5, rand(SVector{2,T}))
    rc = RampControl(.5, rand(SVector{2,T}), rand(SVector{2,T}))
    @test propagate(SI_linear, x0, sc) ≈ propagate(SI_adhoc, x0, sc)
    @test propagate(SI_linear, x0, sc) isa RoboState
    @test propagate(SI_linear, x0, rc) ≈ propagate(SI_adhoc, x0, rc)
    @test propagate(SI_linear, x0, rc) isa RoboState

    for dyn in (DoubleIntegratorDynamics(2),
                LinearDynamics(rand(SMatrix{4,4}), rand(SMatrix{4,2}), rand(SVector{4})))
        dyn_test = TestLinearDynamics(dyn.A, dyn.B, dyn.c)
        @test state_dim(dyn) == 4
        @test control_dim(dyn) == 2

        x0 = rand(SVector{4,T})
        u0 = sc.u
        # Exact vs. ODE Propagation
        @test propagate(dyn, x0, sc) ≈ propagate(dyn_test, x0, sc) atol=1e-3
        @test propagate(dyn, x0, rc) ≈ propagate(dyn_test, x0, rc) atol=1e-3

        # Exact vs. ODE Linearization (+ Reduction)
        X, U = SVector(1,3), SVector(1)
        for u_sc_or_rc in (u0, sc, rc)
            @test linearize(dyn, x0, u_sc_or_rc) ≈ linearize(dyn_test, x0, u_sc_or_rc) atol=1e-3
            @test linearize(dyn, x0, u_sc_or_rc, keep_control_dims=U) ≈
                  linearize(dyn_test, x0, u_sc_or_rc, keep_control_dims=U) atol=1e-3
            @test linearize(dyn, x0, u_sc_or_rc, keep_state_dims=X) ≈
                  linearize(dyn_test, x0, u_sc_or_rc, keep_state_dims=X) atol=1e-3
            @test linearize(dyn, x0, u_sc_or_rc, keep_state_dims=X, keep_control_dims=U) ≈
                  linearize(dyn_test, x0, u_sc_or_rc, keep_state_dims=X, keep_control_dims=U) atol=1e-3
        end
        @test propagate(dyn, x0, sc) ≈ linearize(dyn, x0, sc)(x0, sc)
        @test propagate(dyn, x0, rc) ≈ linearize(dyn, x0, rc)(x0, rc)
    end

    # Compiled vs Ad Hoc Steering
    x0 = rand(SVector{4,T})
    xf = rand(SVector{4,T})

    sol_compiled = bvp_compiled(x0, xf, 10.0)
    sol_adhoc    = bvp_adhoc(x0, xf, 10.0)
    @test sol_compiled.cost ≈ sol_adhoc.cost atol=1e-2
    @test duration(sol_compiled.controls) ≈ duration(sol_adhoc.controls) atol=1e-2
    @test waypoints(DI, x0, sol_compiled.controls, 10) ≈ waypoints(DI, x0, sol_adhoc.controls, 10) atol=1e-2
    @test instantaneous_control(sol_compiled.controls, duration(sol_compiled.controls)/2) ≈
          instantaneous_control(sol_adhoc.controls, duration(sol_adhoc.controls)/2) atol=1e-2
end
