# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMQuad.jl/blob/master/LICENSE

using FEMQuad, Test
using FEMQuad: integrate_3d, get_rule

@testset "Gauss-Legendre quadratures in tetrahedrons" begin
    rules = (:GLTET1, :GLTET4, :GLTET5, :GLTET15)
    f(i) = x -> sum(sum(x)^j for j=0:i)
    r(i::Int) = get_rule(i, rules...)

    @test isapprox(integrate_3d(f(0), r(0)), 1/6)
    @test isapprox(integrate_3d(f(1), r(1)), 7/24)
    @test isapprox(integrate_3d(f(2), r(2)), 47/120)
    @test isapprox(integrate_3d(f(3), r(3)), 19/40)
    @test isapprox(integrate_3d(f(4), r(4)), 153/280)
    @test isapprox(integrate_3d(f(5), r(5)), 341/560)
    #@test isapprox(integrate_3d(f(6), r(6)), 3349/5040)
    #@test isapprox(integrate_3d(f(7), r(7)), 3601/5040)
    #@test isapprox(integrate_3d(f(8), r(8)), 42131/55440)
    #@test isapprox(integrate_3d(f(9), r(9)), 44441/55440)
end
