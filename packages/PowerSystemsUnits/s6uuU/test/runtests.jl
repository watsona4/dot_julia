using Dates
using Test
using PowerSystemsUnits

using Unitful: Unitful, @u_str, J, W, hr


@testset "PowerSystemsUnits.jl" begin
    @testset "Units" begin
        @testset "Period Time Types" begin
            time_stamps = collect(now()-Dates.Day(1):Dates.Hour(1):now())
            offsets = time_stamps - time_stamps[1]

            x = PowerSystemsUnits.dt2umin(Dates.Minute.(offsets))
            y = (offsets)u"minute"
            @test x == y
        end
        @testset "Power Related Unit" begin
            @test 1u"Wh" == 1u"W*hr"
            @test 1u"VARh" == 3600u"J"
            @test 1u"USDPerMWh" == 1u"USD/(MW*hr)"
        end
    end
end
