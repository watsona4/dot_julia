using StaticArrays
using DifferentialDynamicsModels
using SimpleCarModels
using Test

for T in (Float32, Float64)
    dubins_bvp = DubinsSteering(r=T(0.1))
    reedsshepp_bvp = ReedsSheppSteering(r=T(0.1))

    dubins_bvp_v = DubinsSteering(v=T(10), r=T(0.1))
    reedsshepp_bvp_v = ReedsSheppSteering(v=T(10), r=T(0.1))

    for i in 1:1000
        q1 = rand(SE2State{T}).*SVector{3,T}(1, 1, 2π)
        q2 = rand(SE2State{T}).*SVector{3,T}(1, 1, 2π)
        dubins_cost, dubins_control = dubins_bvp(q1, q2)
        reedsshepp_cost, reedsshepp_control = reedsshepp_bvp(q1, q2)
        @test dubins_cost isa T
        @test reedsshepp_cost isa T
        @test dubins_control isa SVector{3,StepControl{2,T,VelocityCurvatureControl{T}}}
        @test reedsshepp_control isa SVector{5,StepControl{2,T,VelocityCurvatureControl{T}}}
        @test dubins_cost >= reedsshepp_cost - sqrt(eps(T))

        dubins_cost_v, dubins_control_v = dubins_bvp_v(q1, q2)
        reedsshepp_cost_v, reedsshepp_control_v = reedsshepp_bvp_v(q1, q2)
        @test dubins_cost ≈ 10*dubins_cost_v
        @test reedsshepp_cost ≈ 10*reedsshepp_cost_v

        @test propagate(dubins_bvp.dynamics, q1, dubins_control) ≈ q2
        @test propagate(reedsshepp_bvp.dynamics, q1, reedsshepp_control) ≈ q2
        @test propagate(dubins_bvp_v.dynamics, q1, dubins_control_v) ≈ q2
        @test propagate(reedsshepp_bvp_v.dynamics, q1, reedsshepp_control_v) ≈ q2
    end
end
