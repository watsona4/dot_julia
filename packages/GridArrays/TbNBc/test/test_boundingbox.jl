
using GridArrays, DomainSets, StaticArrays, Test
@testset "boundingbox" begin
    @test boundingbox(0.0..1.0) == 0.0..1.0
    @test boundingbox((0.0..1.0)^3) == (0.0..1.0)^3
    @test boundingbox(UnitDisk())≈ChebyshevInterval()^2
    @test boundingbox(UnitHyperBall{3}())≈ChebyshevInterval()^3

    @test boundingbox(3UnitDisk())≈(-3.0..3.0)^2
    @test boundingbox(3UnitHyperBall{3}())≈(-3.0..3.0)^3
    @test boundingbox(3*((0.0..1.0)^3))≈ (0.0..3.0)^3
    @test boundingbox(3*(-1.0..2.0))≈ (-3.0..6.0)

    @test boundingbox(3UnitDisk()+SVector(.4,.5))≈(-2.6..3.4)×(-2.5..3.5)
    @test boundingbox(3UnitHyperBall{3}()+SVector(-.4,.5,0.))≈(-3.4..2.6)×(-2.5..3.5)×(-3.0..3.0)

    uniondomain = UnionDomain(3UnitDisk()+SVector(.4,.5)  , 3UnitHyperBall{2}()+SVector(-.4,.5))
    @test boundingbox(uniondomain)≈(-3.4..3.4)×(-2.5..3.5)

    intersectdomain = IntersectionDomain(3UnitDisk()+SVector(.4,.5)  , 3UnitHyperBall{2}()+SVector(-.4,.5))
    @test boundingbox(intersectdomain)≈(-2.6..2.6)×(-2.5..3.5)

    diffdomain = DifferenceDomain(3UnitDisk()+SVector(.4,.5)  , 3UnitHyperBall{2}()+SVector(-.4,.5))
    @test boundingbox(diffdomain)≈(-2.6..3.4)×(-2.5..3.5)
end
