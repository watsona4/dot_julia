module TestConversion
using StaticArrays
using Test
using PhaseSpaceIO
using PhaseSpaceIO.Testing
using PhaseSpaceIO: to_egs, to_iaea, phsp_convert
using Setfield

@testset "to_egs, to_iaea" begin
    for _ in 1:100
        Ni, Nf = rand(0:3,2)
        p_iaea = arbitrary(IAEAParticle{Nf, Ni})
        @set! p_iaea.typ = rand([electron, positron, photon])
        p_egs = to_egs(p_iaea)
        p_iaea2 = to_iaea(p_egs,z=p_iaea.z)
        @test position(p_egs) == position(p_iaea)[1:2]
        @test direction(p_egs) ≈ direction(p_iaea)
        @test particle_type(p_egs) == particle_type(p_iaea)
        @test p_egs.E ≈ p_iaea.E
        @test p_egs.new_history == p_iaea.new_history
        @test p_egs.weight == p_iaea.weight
        
        @test position(p_iaea) ≈ position(p_iaea2)
        @test direction(p_iaea) ≈ direction(p_iaea2)
        @test particle_type(p_iaea2) == particle_type(p_iaea)
        @test p_iaea2.E ≈ p_iaea.E
        @test p_iaea2.new_history == p_iaea.new_history
        @test p_egs.weight == p_iaea.weight
        
        p_iaea_bad = @set p_iaea.typ = rand([proton, neutron])
        @test_throws ArgumentError to_egs(p_iaea_bad)
    end

    # latch and ZLAST
    p_egs = arbitrary(EGSParticle{Float32})
    p_iaea = to_iaea(p_egs, z=0)
    @test p_iaea.extra_floats === (p_egs.zlast,)
    ilatch = Int32(UInt32(p_egs.latch))
    @test p_iaea.extra_ints === (ilatch, )
end

@testset "phsp_convert" begin

    src = assetpath("photon_electron_positron.egsphsp")
    dst = IAEAPath(tempname())
    z = rand(Float32)

    phsp_convert(src, dst, z=z)
    ps_egs = phsp_iterator(collect, src)
    ps_iaea = phsp_iterator(collect, dst)
    ps_iaea2 = map(ps_egs) do p
        to_iaea(p,z=z)
    end

    @test ps_iaea == ps_iaea2
end

end#module
