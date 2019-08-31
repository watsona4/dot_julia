# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMQuad.jl/blob/master/LICENSE

using FEMQuad, Test
using FEMQuad: get_rule, integrate_1d, integrate_2d, integrate_3d

f(i) = x -> sum(sum(x)^j for j=0:i)

@testset "Gauss-Legendre quadratures in one dimension" begin
    # Gaussian quadrature using N points can provide the exact integral if
    # polynomial degree of f is 2N-1 or less => N = (deg(f)+1)/2

    rules = (:GLSEG1, :GLSEG2, :GLSEG3, :GLSEG4, :GLSEG5)
    r(i::Int) = get_rule(i, rules...)

    @test isapprox(integrate_1d(f(0), r(0)), 2.0)
    @test isapprox(integrate_1d(f(1), r(1)), 2.0)
    @test isapprox(integrate_1d(f(2), r(2)), 8/3)
    @test isapprox(integrate_1d(f(3), r(3)), 8/3)
    @test isapprox(integrate_1d(f(4), r(4)), 46/15)
    @test isapprox(integrate_1d(f(5), r(5)), 46/15)
    @test isapprox(integrate_1d(f(6), r(6)), 352/105)
    @test isapprox(integrate_1d(f(7), r(7)), 352/105)
    @test isapprox(integrate_1d(f(8), r(8)), 1126/315)
    @test isapprox(integrate_1d(f(9), r(9)), 1126/315)
end

@testset "Gauss-Legendre quadratures in quadrilaterals" begin
    rules = (:GLQUAD1, :GLQUAD4, :GLQUAD9, :GLQUAD16, :GLQUAD25)
    r(i::Int) = get_rule(i, rules...)

    @test isapprox(integrate_2d(f(0), r(0)), 4.0)
    @test isapprox(integrate_2d(f(1), r(1)), 4.0)
    @test isapprox(integrate_2d(f(2), r(2)), 20/3)
    @test isapprox(integrate_2d(f(3), r(3)), 20/3)
    @test isapprox(integrate_2d(f(4), r(4)), 164/15)
    @test isapprox(integrate_2d(f(5), r(5)), 164/15)
    @test isapprox(integrate_2d(f(6), r(6)), 2108/105)
    @test isapprox(integrate_2d(f(7), r(7)), 2108/105)
    @test isapprox(integrate_2d(f(8), r(8)), 13492/315)
    @test isapprox(integrate_2d(f(9), r(9)), 13492/315)
end

@testset "Gauss-Legendre quadratures in hexahedrons" begin
    rules = (:GLHEX1, :GLHEX8, :GLHEX27, :GLHEX64, :GLHEX125)
    r(i::Int) = get_rule(i, rules...)

    @test isapprox(integrate_3d(f(0), r(0)), 8.0)
    @test isapprox(integrate_3d(f(1), r(1)), 8.0)
    @test isapprox(integrate_3d(f(2), r(2)), 16.0)
    @test isapprox(integrate_3d(f(3), r(3)), 16.0)
    @test isapprox(integrate_3d(f(4), r(4)), 184/5)
    @test isapprox(integrate_3d(f(5), r(5)), 184/5)
    @test isapprox(integrate_3d(f(6), r(6)), 12064/105)
    @test isapprox(integrate_3d(f(7), r(7)), 12064/105)
    @test isapprox(integrate_3d(f(8), r(8)), 9928/21)
    @test isapprox(integrate_3d(f(9), r(9)), 9928/21)
end
