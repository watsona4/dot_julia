############## radius.jl  ###############

import RiemannTheta.radius

≈(a,b) = isapprox(a, b, rtol=1e-1)

@testset "radius" begin

    @test radius(ϵ1, T1) ≈ 3.4
    @test radius(ϵ2, T1) ≈ 5.0
    @test radius(ϵ1, T2) ≈ 3.4
    @test radius(ϵ2, T2) ≈ 5.0
    @test radius(ϵ1, T3) ≈ 4.7
    @test radius(ϵ2, T3) ≈ 6.7

    @test radius(ϵ1, T1, derivs1) ≈ 4.1
    @test radius(ϵ1, T3, derivs2) ≈ 9.1

end

############## innerpoints  ###################

import RiemannTheta.innerpoints

@testset "innerpoints" begin

    R = radius(ϵ1, T1)
    pts = innerpoints(T1, R)
    @test length(pts) > 17
    @test length(pts) < 30
    @test all(length.(pts) .== 2)

    R = radius(ϵ2, T3)
    pts = innerpoints(T3, R)
    @test length(pts) > 100
    @test length(pts) < 300
    @test all(length.(pts) .== 10)

end

########### finite_sum.jl ##############

########### lll.jl ##############
