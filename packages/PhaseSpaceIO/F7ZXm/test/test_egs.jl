module TestEGS
using Test
using PhaseSpaceIO
using PhaseSpaceIO.Testing
using PhaseSpaceIO: ptype, EGSHeader, write_header, write_particle, EGSParticle
using Setfield

@testset "test egs_iterator egs_writer" begin
    for _ in 1:100
        ZSLAB = rand(Bool) ? Nothing : Float32
        n = rand(1:1000)
        P = EGSParticle{ZSLAB}
        ps = P[arbitrary(P) for _ in 1:n]
        path = tempname() * ".egsphsp1"
        egs_writer(path,P) do w
            for p in ps
                write(w, p)
            end
        end
        @test ispath(path)
        ps_reload = egs_iterator(collect, path)
        ps_reload2 = phsp_iterator(collect, path)
        @test ps == ps_reload
        @test ps_reload2 == ps_reload
        @test eltype(ps) == eltype(ps_reload)
        rm(path)
    end
end

@testset "simple phase spaces" begin
    
    path = assetpath("photon_electron_positron.egsphsp")
    h_truth = PhaseSpaceIO.EGSHeader{EGSParticle{Float32}}(3, 1, 1.0f0, 0.83312154f0, 1.0f0)
    ps_truth = [
                EGSParticle(
                    E=1.0, weight=5.2134085, x=2.0, y=-3.0,
                    u=0.99884456, v=-0.03811472, w=0.029271236,
                    new_history=false, zlast=0.23947382f0, latch=Latch(charge=0))
                EGSParticle(
                    E=0.8331216, weight=9.296892, x=-0.41874805, y=-0.04104328,
                    u=0.18903294, v=-0.29983893, w=-0.93507385,
                    new_history=true, zlast=1.3316472f0, latch=Latch(charge=-1))
                EGSParticle(
                    E=0.6077692, weight=0.8328271, x=0.922653, y=0.9263571,
                    u=0.22435355, v=-0.41052637, w=-0.8838176,
                    new_history=false, zlast=1.0724568f0, latch=Latch(charge=1))
    ]
    h_loaded, ps_loaded = phsp_iterator(path) do iter
        iter.header, collect(iter)
    end
    @test ps_truth[1] == ps_loaded[1]
    @test ps_truth[2] == ps_loaded[2]
    @test ps_truth[3] == ps_loaded[3]
    @test ps_truth == ps_loaded
    @test h_truth == h_loaded
end

@testset "finalizer" begin
    function write_sloppy(path, ps)
        P = eltype(ps)
        w = egs_writer(path, P)
        for p in ps
            write(w, p)
        end
    end
    path = tempname() * ".egsphsp"
    ps = [arbitrary(EGSParticle{Nothing})]
    write_sloppy(path, ps)
    GC.gc()
    ps2 = phsp_iterator(collect, path)
    @test length(ps) == length(ps2) == 1
    @test first(ps) ≈ first(ps2)
    rm(path)
end

@testset "Latch" begin
    l0 = Latch(zero(UInt32))

    # binary represenation taken from beamdp
    l = @set l0.creation = 5
    @test 0b00000101000000000000000000000000 === UInt32(l)

    l = @set l0.brems = true
    @test 0b00000000000000000000000000000001 === UInt32(l)

    l = @set l0.visited = @BitRegions(2,4,7,21)
    @test 0b00000000001000000000000010010100 === UInt32(l)

    l = @set l.creation = 3
    @set! l.visited = @BitRegions(1,3,23)
    @test 0b00000011100000000000000000001010 === UInt32(l)
end

@testset "particle_type" begin
    p = EGSParticle(latch=Latch(multicross=false, charge=0, creation=0, visited=@BitRegions(), brems=false, ), new_history=true, E=0.74988735f0, x=-0.51910776f0, y=0.22886558f0, u=0.26358783f0, v=-0.9477993f0, w=-0.17943771f0, weight=4.7387686f0, zlast=nothing, )
    @test particle_type(p) === photon
    @test isphoton(p)
    @set! p.latch.charge = -1
    @test iselectron(p)
    @test particle_type(p) === electron
    @set! p.latch.charge = 1
    @test particle_type(p) === positron
    @test ispositron(p)
end

end #module
