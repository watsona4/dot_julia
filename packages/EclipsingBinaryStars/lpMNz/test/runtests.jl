#=
    tests
    Copyright © 2018 Mark Wells <mwellsa@gmail.com>

    Distributed under terms of the AGPL-3.0 license.
=#

using Test

import Unitful: d, rad, °, Mass, Time, Length
using Unitful
using UnitfulAstro: yr, Msun, Rsun, AU, GMsun

#push!(LOAD_PATH, "../src/")
using EclipsingBinaryStars

#pri = Star(5Msun, 2Rsun)
#sec = Star(1Msun, 1Rsun)
#a = 20.0Rsun
#ε = 0.5
#i = deg2rad(90)*rad
#ω = (pi/3)*rad
#orb = Orbit(a, ε, i, ω)
#binary = getBinary(pri, sec, orb)
#pnt₁,pnt₂ = eclipse_morphs(binary)

@testset "eclipse morphology testing" begin
    pri = Star(5Msun, 2Rsun)
    sec = Star(1Msun, 1Rsun)
    a = 20.0Rsun
    ε = 0.5
    i = deg2rad(90)*rad
    ω = (pi/3)*rad
    orb = Orbit(a, ε, i, ω)
    binary = getBinary(pri, sec, orb)
    pnt₁,pnt₂ = eclipse_morphs(binary)
    
    @test pnt₁.ν ≈ (π/2)rad - orb.ω
    @test pnt₂.ν ≈ (3π/2)rad - orb.ω
    @test pnt₁.m == EclipseType(3)
    #@show pnt₁.m
    @test pnt₂.m == EclipseType(5)
    #@show pnt₂.m
    
    pri = Star(5Msun, 2Rsun)
    sec = Star(1Msun, 1Rsun)
    a = 20.0Rsun
    ε = 0.5
    i = deg2rad(0)*rad
    ω = (pi/3)*rad
    orb = Orbit(a, ε, i, ω)
    binary = getBinary(pri, sec, orb)
    pnt₁,pnt₂ = eclipse_morphs(binary)

    @test pnt₁.ν ≈ (π/2)rad - orb.ω
    @test pnt₂.ν ≈ (3π/2)rad - orb.ω
    @test pnt₁.m == EclipseType(0)
    #@show pnt₁.m
    @test pnt₂.m == EclipseType(0)
    #@show pnt₂.m
    
    pri = Star(5Msun, 1Rsun)
    sec = Star(1Msun, 2Rsun)
    a = 20.0Rsun
    ε = 0.5
    i = deg2rad(87)*rad
    ω = (pi/6)*rad
    orb = Orbit(a, ε, i, ω)
    binary = getBinary(pri, sec, orb)
    pnt₁,pnt₂ = eclipse_morphs(binary)

    @test pnt₁.ν ≈ (π/2)rad - orb.ω
    @test pnt₂.ν ≈ (3π/2)rad - orb.ω
    @test pnt₁.m == EclipseType(2)
    #@show pnt₁.m
    @test pnt₂.m == EclipseType(4)
    #@show pnt₂.m

    pri = Star(5Msun, 2Rsun)
    sec = Star(1Msun, 1Rsun)
    a = 20.0Rsun
    ε = 0.5
    i = deg2rad(80)*rad
    ω = (pi/3)*rad
    orb = Orbit(a, ε, i, ω)
    binary = getBinary(pri, sec, orb)
    pnt₁,pnt₂ = eclipse_morphs(binary)

    @test pnt₁.ν ≈ (π/2)rad - orb.ω
    @test pnt₂.ν ≈ (3π/2)rad - orb.ω
    @test pnt₁.m == EclipseType(1)
    #@show pnt₁.m
    @test pnt₂.m == EclipseType(0)
    #@show pnt₂.m

    pri = Star(5Msun, 1Rsun)
    sec = Star(1Msun, 2Rsun)
    a = 20.0Rsun
    ε = 0.5
    i = deg2rad(90)*rad
    ω = (pi/3)*rad
    orb = Orbit(a, ε, i, ω)
    binary = getBinary(pri, sec, orb)
    pnt₁,pnt₂ = eclipse_morphs(binary)

    @test pnt₁.ν ≈ (π/2)rad - orb.ω
    @test pnt₂.ν ≈ (3π/2)rad - orb.ω
    @test pnt₁.m == EclipseType(2)
    #@show pnt₁.m
    @test pnt₂.m == EclipseType(6)
    #@show pnt₂.m
end

@testset "transit duration testing" begin
    pri = Star(5Msun, 2Rsun)
    sec = Star(1Msun, 1Rsun)

    for ω in (0:π/3:2π)rad
        for ε in 0:0.1:1-eps()
            a = 20Rsun
            i = deg2rad(90)rad
            orb = Orbit(a,ε,i,ω)
            binary = getBinary(pri, sec, orb)
            
            ν₁ = 0.0π*rad
            ν₂ = 1.0π*rad
            ν₃ = 2.0π*rad
            time1 = EclipsingBinaryStars.get_time_btw_νs(binary, ν₁, ν₂)
            time2 = EclipsingBinaryStars.get_time_btw_νs(binary, ν₂, ν₃)
            @test time1 ≈ time2
            @test time1 ≈ time2

            ν₁ = 1.5π*rad
            ν₂ = 0.0π*rad
            ν₃ = 0.5π*rad
            time1 = EclipsingBinaryStars.get_time_btw_νs(binary, ν₁, ν₂)
            time2 = EclipsingBinaryStars.get_time_btw_νs(binary, ν₂, ν₃)
            @test time1 ≈ time2

            ν₁ = 1.5π*rad
            ν₂ = 2.0π*rad
            ν₃ = 0.5π*rad
            time1 = EclipsingBinaryStars.get_time_btw_νs(binary, ν₁, ν₂)
            time2 = EclipsingBinaryStars.get_time_btw_νs(binary, ν₂, ν₃)
            @test time1 ≈ time2
        end
    end
end

@testset "rlof_test" begin
    # Moe & Di Stefano 2017 page 48
    #   Solar-type primaries with M₁ ≈ 1.0 Msun expand to R₁ ≈ 250Rsun at the tip of the AGB
    #   (Bertelli et al. 2008).
    #
    #   We adopt ⟨ε⟩ = 0.5, and so solar-type binaries with a ≲ 2.2R₁/(1 - ⟨ε⟩) ≈ 1100 Rsun ≈ 5 au
    #   will fill their Roche lobes at periastron (Eggleton 1983). According to Kepler's laws,
    #   solar-type binaries with P ≲ 10 yr, i.e., logP (days) < 3.6, undergo RLOF.
    #
    #   Meanwhile, massive stars with M₁ > 15 Msun expand to much larger radii R₁ = 700–1200 Rsun
    #   during their red supergiant phase (Bertelli et al. 2009). Early-type binaries can fill
    #   their Roche lobes across even wider separations a ≲ 2.2R₁/(1 - ⟨e⟩) ≈ 4000Rsun ≈ 19 au.
    #   Assuming M₁ = 20Msun and the average mass ratio ⟨q⟩ = 0.3 of massive binaries with
    #   intermediate periods (Section 9.1; Figure 35), early-type binaries with P ≲ 16 yr, i.e.,
    #   logP (days) ≲ 3.8, undergo RLOF.
    pri = Star(1Msun, 250Rsun)
    sec = Star(0.7Msun, 0.7Rsun)
    ε = 0.5
    orb = Orbit( 2.2*pri.r/(1 - ε)
               , ε, 0rad, 0rad
               )
    binary = getBinary(pri, sec, orb)
    #println("primary = ", binary.pri)
    #println("(r₁/a)*a = ",binary.roche.r₁_a*binary.orb.a*(1 - binary.orb.ε))
    #println("RLOF = ", binary.roche.rlof₁)
    @test binary.roche.rlof₁ == true
    #println("secondary = ", binary.sec)
    #println("(r₂/a)*a = ",binary.roche.r₂_a*binary.orb.a*(1 - binary.orb.ε))
    #println("RLOF = ", binary.roche.rlof₂)
    @test binary.roche.rlof₂ == false

    println()
    pri = Star(20Msun, 1050Rsun)
    sec = Star(5Msun, 3Rsun)
    #p = uconvert(d, 16yr)
    p = 16yr
    binary = getBinary(pri, sec, p, ε, 0rad, 0rad)
    #println("primary = ", binary.pri)
    #println("(r₁/a)*a = ",binary.roche.r₁_a*binary.orb.a*(1 - binary.orb.ε))
    #println("RLOF = ", binary.roche.rlof₁)
    @test binary.roche.rlof₁ == true

    #println("secondary = ", binary.sec)
    #println("(r₂/a)*a = ",binary.roche.r₂_a*binary.orb.a*(1 - binary.orb.ε))
    #println("RLOF = ", binary.roche.rlof₂)
    @test binary.roche.rlof₂ == false
end

@testset "visible_frac_exhaustive" begin
    pri = Star(5Msun, 2Rsun)
    sec = Star(1Msun, 1Rsun)
    
    a_range = [3.0, 30.0, 300.0, 3000.0, 30000.0]
    
    for ν in 0:π/3:2π
        for ω in 0:π/3:2π
            for i in 0:π/10:π/2
                for ε in 0:0.1:1-eps()
                    for a in a_range
                        orb = Orbit(a*Rsun, ε, i*rad, ω*rad)
                        binary = getBinary(pri, sec, orb)
                        
                        fracs = frac_visible_area(binary, ν*rad)
                        # they can't both be eclipsed at the same time
                        @test any(fracs .== 1)
                        # fractions cannot be less than 0
                        @test .!any(fracs .< 0)
                        # fractions cannot be greater than 1
                        @test .!any(fracs .> 1)

#                        valid_binary = periastron_check(binary)
#                        if valid_binary
#                        end
                    end
                end
            end
        end
    end
end
#
@testset "critical_νs" begin
    pri = Star(5Msun, 2Rsun)
    sec = Star(1Msun, 1Rsun)
    
    a_range = [3.0, 30.0, 300.0, 3000.0, 30000.0]*Rsun
    
    ωs = collect(0:π/3:2π)*rad
    is = collect(0:π/10:π/2)*rad
    for ω in ωs
        for i in is
            for ε in 0:0.1:1-eps()
                for a in a_range
                    #@show (ν,ω,i,ε,a)
                    orb = Orbit(a, ε, i, ω)
                    binary = getBinary(pri, sec, orb)
                    
                    #valid_binary = periastron_check(binary)
                    #if valid_binary
                    e1,e2 = eclipse_morphs(binary)
                    νs = [e1.ν, e2.ν]
                    ms = [e1.m, e2.m]

                    for (ν_e,m) in zip(νs,ms)
                        if m != EclipseType(0)
                            νs_c = EclipsingBinaryStars.get_outer_critical_νs(binary, ν_e)
                            eclip_time = get_time_btw_νs(binary, νs_c[1], νs_c[2])
                            @test eclip_time < binary.P
                        end
                        if m in [EclipseType(2),EclipseType(3),EclipseType(5),EclipseType(6)]
                            νs_c = EclipsingBinaryStars.get_inner_critical_νs(binary, ν_e)
                            eclip_time = get_time_btw_νs(binary, νs_c[1], νs_c[2])
                            @test eclip_time < binary.P
                        end
                    end
                end
            end
        end
    end
end
