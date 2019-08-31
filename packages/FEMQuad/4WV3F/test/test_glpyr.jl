# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMQuad.jl/blob/master/LICENSE

using FEMQuad, Test
using FEMQuad: integrate_3d, get_rule

@testset "Gauss-Legendre quadratures in pyramids" begin
    # FIXME: fix tests
    f(i) = x -> sum(sum(x)^j for j=0:i)
    @test isapprox(integrate_3d(f(0), :GLPYR5B), 4.0/6.0)
    #@test isapprox(integrate_3d(f(1), :GLPYR5B), 7.0/6.0)
end
