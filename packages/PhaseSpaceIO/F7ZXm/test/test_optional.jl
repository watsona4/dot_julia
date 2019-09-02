module TestOptional
using StaticArrays
using Rotations
using CoordinateTransformations
using Test
using PhaseSpaceIO
using PhaseSpaceIO.Testing
using Setfield

@testset "position, direction" begin
    dir = StaticArrays.normalize(@SVector(randn(3)))
    pos_iaea = @SVector(randn(3))
    pos_egs = @SVector(randn(2))
    for (p, pos, dir) in [
                          (arbitrary(EGSParticle{Float32}), pos_egs, dir),
                          (arbitrary(IAEAParticle{2,3}), pos_iaea, dir),
           ]
        q = set_position(p, pos)
        @test typeof(q) == typeof(p)
        @test q.E === p.E
        @test position(q) ≈ pos
        
        q = set_direction(p, dir)
        @test typeof(q) == typeof(p)
        @test q.E === p.E

        @test direction(q) ≈ dir
        @test dir ≈ [q.u, q.v, q.w]
    end

    p = arbitrary(EGSParticle{Nothing})
    @test position(p) == [p.x, p.y]
    @test position(p,z=3) == [p.x, p.y, 3]

    p = arbitrary(IAEAParticle{1,2})
    @test position(p) == [p.x, p.y, p.z]
end

@testset "coordinate transformations" begin
    p = arbitrary(IAEAParticle{1,2})

    t = Translation(randn(3))
    @test position(t(p)) ≈ t(position(p))
    @test direction(p) ≈ direction(t(p))

    l = LinearMap(rand(AngleAxis))
    @test position(l(p)) ≈ l(position(p))
    @test l(direction(p)) ≈ direction(l(p))

    tl = t ∘ l
    @test position(tl(p)) ≈ position(t(l(p)))
    @test direction(tl(p)) ≈ direction(l(p))
end

end#module
