#=
    logp_eccn_tests
    Copyright © 2018 Mark Wells <mwellsa@gmail.com>

    Distributed under terms of the AGPL-3.0 license.
=#

include("../src/EclipsingBinaryStars.jl")

#@testset "detached potential check" begin
fake_pri = getStar(m=5, r=2)
fake_sec = getStar(m=1, r=1)

#a_range = [3.0, 30.0, 300.0, 3000.0, 30000.0]
#εs = 0:0.1:1-eps()
ε = 0.4
i = π/2
ω = 0
#logp = 0.5
logps = 0.2:0.1:1.0

#for ε in εs
for logp in logps
    a = EclipsingBinaryStars.k3_P_to_a( fake_pri
                                      , fake_sec
                                      , P = 10.0^logp
                                      , ω = ω
                                      , ε = ε
                                      , i = i
                                      )
    fake_orb = getOrbit(ω=ω, ε=ε, i=i, a=a)
    fake_bin = getBinary(fake_pri, fake_sec, fake_orb)

    nus, morphs = determine_eclipsing_morphologies(fake_bin)
    for (n,m) in zip(nus,morphs)
        println(m,": ", m)
        println("ε: ", ε)
        println("logp: ", logp)
        println("nu: ", n)
        tdur = get_transit_duration_totann(fake_bin, n)
        println("tdur_tot: ", tdur)
        tdur = get_transit_duration_partial(fake_bin, n)
        println("tdur_par: ", tdur)
        vfrac = get_visible_frac(fake_bin,n)
        println("vfracs: ", vfrac[1], ", ", vfrac[2])
        println()
    end
end

 
