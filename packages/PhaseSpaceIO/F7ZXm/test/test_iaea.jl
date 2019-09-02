module TestIAEA
using Test
using PhaseSpaceIO
using PhaseSpaceIO.Testing
using Setfield
using PhaseSpaceIO: ptype, read_particle, write_particle

@testset "IAEA save load with many consants" begin
    h = IAEAHeader{0,0}((x=1, y=2, z=3, u=0, v=1, weight=5))
    p_truth = IAEAParticle(x=1,y=2,z=3,u=0,v=1,w=0,weight=5, typ=photon, E=6)
    path = IAEAPath(tempname())
    iaea_writer(path, h) do w
        write(w, p_truth)
    end
    
    r_reloaded, ps_reloaded = phsp_iterator(path) do iter
        iter.header.record_contents, collect(iter)
    end
    @test r_reloaded == h.record_contents
    @test length(ps_reloaded) == 1
    @test first(ps_reloaded) == p_truth
    rm(path)
end

@testset "finalizer" begin
    function write_sloppy(path, ps, r)
        w = iaea_writer(path, r)
        for p in ps
            write(w, p)
        end
    end
    path = IAEAPath(tempname())
    ps = [arbitrary(IAEAParticle{0,1})]
    r = IAEAHeader{0,1}()
    write_sloppy(path, ps, r)
    GC.gc()
    ps2 = phsp_iterator(collect, path)
    @test length(ps) == length(ps2) == 1
    @test first(ps) ≈ first(ps2)
    rm(path)
end

@testset "read write single particle" begin
    h = IAEAHeader{0,1}()
    P = ptype(h)
    @test P == IAEAParticle{0,1}
    p_ref = P(photon, 
        1.0f0, 2.0f0, 
        3.0f0, 4.0f0, 5.0f0, 
        0.53259337f0, 0.3302265f0, -0.7792912f0, 
        true, (), (13,))
    
    path = assetpath("some_file.IAEAphsp")
    ps = iaea_iterator(collect, path)
    @test length(ps) == 1
    @test first(ps) == p_ref
    iaea_iterator(path) do iter
        @test iter.header.attributes[:INSTITUTION] == "hello world"
        @test iter.header.attributes[:ORIG_HISTORIES] == "18446744073709551615"
    end
    
    io = IOBuffer()
    write_particle(io, p_ref, h)
    seekstart(io)
    p = @inferred read_particle(io, h)
    @test p === p_ref
    @test eof(io)
end

@testset "test IAEAPhspIterator" begin
    path = assetpath("some_file.IAEAphsp")
    phsp = iaea_iterator(path)
    @test length(phsp) == 1
    @test eltype(phsp) === IAEAParticle{0,1}
    @test collect(phsp) == collect(phsp)
    @test length(collect(phsp)) == 1
    close(phsp)
end

function test_header_contents(path)
    s = read(path, String)
    for key in [
        :IAEA_INDEX,
        :TITLE,
        :FILE_TYPE,
        :CHECKSUM,
        :RECORD_LENGTH,
        :BYTE_ORDER,
        :ORIG_HISTORIES,
        :PARTICLES,
        :TRANSPORT_PARAMETERS,
        :MACHINE_TYPE,
        :MONTE_CARLO_CODE_VERSION,
        :GLOBAL_PHOTON_ENERGY_CUTOFF,
        :GLOBAL_PARTICLE_ENERGY_CUTOFF,
        :COORDINATE_SYSTEM_DESCRIPTION,
        :BEAM_NAME,
        :FIELD_SIZE,
        :NOMINAL_SSD,
        :MC_INPUT_FILENAME,
        :VARIANCE_REDUCTION_TECHNIQUES,
        :INITIAL_SOURCE_DESCRIPTION,
        :PUBLISHED_REFERENCE,
        :AUTHORS,
        :INSTITUTION,
        :LINK_VALIDATION,
        :ADDITIONAL_NOTES,]
        @test occursin(string(key), s)
    end
end

@testset "test iaea_iterator iaea_writer" begin
    for _ in 1:100
        f = rand(1:3)
        i = rand(1:3)
        n = rand(1:1000)
        ps = [arbitrary(IAEAParticle{f,i}) for _ in 1:n]
        r = IAEAHeader{f,i}()
        dir = tempname()
        mkpath(dir)
        path = IAEAPath(joinpath(dir, "hello"))
        iaea_writer(path,r) do w
            for p in ps
                write(w, p)
            end
        end
        @test ispath(path.header)
        @test ispath(path.phsp)
        test_header_contents(path.header)

        ps_reload = iaea_iterator(collect, path)
        @test all(ps_reload .≈ ps)
        @test eltype(ps_reload) === eltype(ps)
        rm(path)

        @test !ispath(path.header)
        @test !ispath(path.phsp)
    end
end

end #module
