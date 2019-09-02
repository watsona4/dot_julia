module TestCore
using PhaseSpaceIO
using PhaseSpaceIO.Testing: arbitrary
using Test
using Base.Meta

@testset "show" begin
    p_iaea = IAEAParticle(typ=photon,E=1.23,x=1,y=2,z=3,
                 u=0,v=0,w=1)
    p_egs = EGSParticle(latch=Latch(charge=1), E=1.23, x=1, y=2,
                        u=0,v=0,w=1)
    for p in [p_egs, p_iaea,]
        io = IOBuffer()
        s = sprint(show, p)
        for prop in propertynames(p)
            sprop = string(prop)
            @test occursin(sprop, s)
        end
                     
        ex = Meta.parse(s)
        @test eval(ex) === p
    end
end

end#module
