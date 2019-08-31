# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMQuad.jl/blob/master/LICENSE

using FEMQuad, Test
using FEMQuad: integrate_2d, get_rule

@testset "Gauss-Legendre quadratures in triangles" begin
    rules = (:GLTRI1, :GLTRI3, :GLTRI4, :GLTRI6, :GLTRI7, :GLTRI12)
    f(i) = x -> sum(sum(x)^j for j=0:i)
    r(i::Int) = get_rule(i, rules...)

    @test isapprox(integrate_2d(f(0), r(0)), 1/2)
    @test isapprox(integrate_2d(f(1), r(1)), 5/6)
    @test isapprox(integrate_2d(f(2), r(2)), 13/12)
    @test isapprox(integrate_2d(f(3), r(3)), 77/60)
    @test isapprox(integrate_2d(f(4), r(4)), 29/20)
    @test isapprox(integrate_2d(f(5), r(5)), 223/140)
    @test isapprox(integrate_2d(f(6), r(6)), 481/280)
    #@test isapprox(integrate_2d(f(7), r(7)), 4609/2520)
    #@test isapprox(integrate_2d(f(8), r(8)), 4861/2520)
    #@test isapprox(integrate_2d(f(9), r(9)), 55991/27720)
end

@testset "Gauss-Legendre quadratures in triangles B" begin
    rules = (:GLTRI1, :GLTRI3B, :GLTRI4B, :GLTRI6, :GLTRI7, :GLTRI12)
    f(i) = x -> sum(sum(x)^j for j=0:i)
    r(i::Int) = get_rule(i, rules...)

    @test isapprox(integrate_2d(f(2), r(2)), 13/12)
    @test isapprox(integrate_2d(f(3), r(3)), 77/60)
end
