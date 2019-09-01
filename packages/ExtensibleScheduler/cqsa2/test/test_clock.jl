using Test
using ExtensibleScheduler
using ExtensibleScheduler: real_time_clock, ClockException

@testset "Clocks" begin
    @testset "RealTimeClock" begin
        @test now(real_time_clock) isa DateTime

        @test_throws ClockException set(real_time_clock, DateTime(2010, 1, 1))
    end

    @testset "SimClock" begin
        dt_start = DateTime(2010, 1, 1, 13, 37)
        dt = dt_start
        clock = SimClock(dt)
        now_ = now(clock) 
        @test now_ isa DateTime
        @test now_ == dt_start
        dt += Dates.Minute(1)
        set(clock, dt)
        @test now(clock) == dt

        dt -= Dates.Minute(2)
        @test_throws ClockException set(clock, dt)

    end
end