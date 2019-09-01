using DifferentialDynamicsModels
using StaticArrays
using Test

@maintain_type struct RoboState{T} <: FieldVector{2,T}
    x::T
    y::T
end
x0 = RoboState(1., 1.)
xf = RoboState(4., 5.)
@test x0 + xf isa RoboState

SI = SingleIntegratorDynamics{2}()
@test state_dim(SI) == 2
@test control_dim(SI) == 2

bvp = SteeringBVP(SI, Time(), constraints=BoundedControlNorm())
@test issymmetric(bvp)
sol = bvp(x0, xf)
@test sol == bvp(x0, xf, Inf)
@test sol.cost ≈ 5
@test sol.controls isa StepControl{2,Float64,SVector{2,Float64}}
@test sol.controls.t ≈ 5
@test sol.controls.u ≈ SVector(.6, .8)

ctrl = sol.controls
@test propagate(SI, x0, ctrl) isa RoboState
@test propagate(SI, x0, ctrl) ≈ xf
@test propagate(SI, x0, fill(ctrl, 2)) isa RoboState
@test propagate(SI, x0, fill(ctrl, 2)) ≈ RoboState(7., 9.)

@test propagate(SI, x0, ctrl, -1:1:duration(ctrl)+1) ≈ [x0, [x0 + i*(xf-x0)/5 for i in 0:5]..., xf]
@test waypoints(SI, x0, fill(ctrl, 2), 1.0) ≈ waypoints(SI, x0, fill(ctrl, 2), 11)

c1 = StepControl(.5, rand(SVector{2,Float64}))
c2 = StepControl(.5, rand(SVector{2,Float64}))
@test instantaneous_control([c1, c2], .25) == c1.u
@test instantaneous_control([c1, c2], .75) == c2.u
@test propagate(SI, x0, [c1, c2]) == x0 + 0.5*c1.u + 0.5*c2.u

rc = RampControl(.5, rand(SVector{2,Float64}), rand(SVector{2,Float64}))
@test propagate(SI, x0, rc) ≈ DifferentialDynamicsModels.propagate_ode(SI, x0, rc)
