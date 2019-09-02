module TestAPI
using Test
using PhaseSpaceIO
using PhaseSpaceIO.Testing
using Random

@testset "read write api" begin
    root = tempname()
    examples = [
    (
     format = :egs,
     path = joinpath(root, randstring() * ".egsphsp"),
     ps = [arbitrary(EGSParticle{Nothing})],
    ),
    (
     format = :iaea,
     path = IAEAPath(joinpath(root, randstring())),
     ps = [arbitrary(IAEAParticle{0,1})]
    ),
    (
     format = :iaea,
     path = joinpath(root, randstring() * ".IAEAheader"),
     ps = [arbitrary(IAEAParticle{0,1})],
    ),
    (
     format = :iaea,
     path = joinpath(root, randstring() * ".IAEAphsp"),
     ps = [arbitrary(IAEAParticle{0,1})],
    )
   ]
    for ex in examples
        if ex.format === :egs
            native_write = egs_write
            native_iterator = egs_iterator
        else
            @assert ex.format === :iaea
            native_write = iaea_write
            native_iterator  = iaea_iterator
        end
        for xxx_write in [native_write, phsp_write]
            mkdir(root)
            xxx_write(ex.path, ex.ps)
            for xxx_iterator in [native_iterator, phsp_iterator]
                ps1 = xxx_iterator(collect, ex.path)
                iter = xxx_iterator(ex.path)
                ps2 = collect(iter)
                close(iter)
                @test all(ps1 .≈ ex.ps)
                @test ps1 == ps2
            end
            rm(root, recursive=true)
        end
    end
end

end#module
