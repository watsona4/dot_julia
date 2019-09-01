#=
    detached_tests
    Copyright © 2018 Mark Wells <mwellsa@gmail.com>

    Distributed under terms of the AGPL-3.0 license.
=#

#@testset "detached potential check" begin
fake_pri = getStar(m=5, r=2)
fake_sec = getStar(m=1, r=1)

a_range = [3.0, 30.0, 300.0, 3000.0, 30000.0]
ωs      = 0:π/3:2π
eyes    = 0:π/10:π/2
εs      = 0:0.1:1-eps()

nruns = length(a_range)*length(ωs)*length(eyes)*length(εs)

binaries = Array{EclipsingBinaryStars.Binary,1}(nruns)
isdetach = Array{Bool,1}(nruns)
j = 1

for ω in ωs
    for i in eyes
        for ε in εs
            for a in a_range
                #@show (ν,ω,i,ε,a)
                fake_orb = getOrbit(ω=ω, ε=ε, i=i, a=a)

                binaries[j] = getBinary(fake_pri, fake_sec, fake_orb)
                isdetach[j] = detached_check(binaries[j])
                j += 1
            end
        end
    end
end
#end
