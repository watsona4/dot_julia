# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMQuad.jl/blob/master/LICENSE

using FEMQuad, Test
using FEMQuad: integrate_3d, get_rule

@testset "Gauss-Legendre quadratures in prismatic domains" begin
    rules = (:GLWED6, :GLWED21)
    f(i) = x -> sum(sum(x)^j for j=0:i)

    @test isapprox(integrate_3d(f(0), :GLWED6), 1.0)
    @test isapprox(integrate_3d(f(1), :GLWED6), 5.0/3.0)
    @test isapprox(integrate_3d(f(0), :GLWED6B), 1.0)
    @test isapprox(integrate_3d(f(1), :GLWED6B), 5.0/3.0)
    @test isapprox(integrate_3d(f(1), :GLWED21), 5.0/3.0)
    @test isapprox(integrate_3d(f(2), :GLWED21), 5.0/2.0)
    @test isapprox(integrate_3d(f(3), :GLWED21), 107.0/30.0)
    @test isapprox(integrate_3d(f(4), :GLWED21), 51.0/10.0)
    @test isapprox(integrate_3d(f(5), :GLWED21), 517.0/70.0)
    #@test isapprox(integrate_3d(f(6), :GLWED21), 4597.0/420.0)
    #@test isapprox(integrate_3d(f(7), :GLWED21), 20959.0/1260.0)
end
