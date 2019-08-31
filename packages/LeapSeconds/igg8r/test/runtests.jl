using LeapSeconds
using Dates: DateTime, Month, year, month, day
using ERFA
using Test

@testset "Leap Seconds" begin
    msg = "UTC is not defined for dates before 1960-01-01."
    @test (@test_logs (:warn, msg) offset_tai_utc(DateTime(1959,1,1,))) == 0.0
    for dt = DateTime(1960,1,1):Month(1):DateTime(2018,12,1)
        y = year(dt)
        m = month(dt)
        d = day(dt)
        @test offset_tai_utc(dt) ≈ ERFA.dat(y, m, d, 0.0)
    end
end
