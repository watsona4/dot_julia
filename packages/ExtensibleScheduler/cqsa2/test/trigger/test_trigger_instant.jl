using Test
using Dates
using ExtensibleScheduler
using ExtensibleScheduler: InstantTrigger, get_next_dt_fire
using Base: IteratorSize, HasLength, length


@testset "InstantTrigger" begin

    @testset "trigger" begin
        dt_fire_at, dt_previous_fire, dt_now, dt_next_fire = DateTime(2009, 7, 6), DateTime(0), DateTime(2008, 5, 4), DateTime(2009, 7, 6)

        trigger = Trigger(dt_fire_at)

        @test trigger isa InstantTrigger
        @test get_next_dt_fire(trigger, dt_previous_fire, dt_now) == dt_next_fire

        @test IteratorSize(trigger) == HasLength()
        @test length(trigger) == 1
    end

    @testset "sample" begin
        n_executed = 0

        function sample_action()
            n_executed += 1
        end

        dt_start = DateTime(2010, 1, 1, 0, 0)
        dt = dt_start
        clock = SimClock(dt)
        sched = BlockingScheduler(clock=clock, delayfunc=NoSleep)
        action = Action(sample_action)
        add(sched, action, Trigger(DateTime(2010, 1, 1, 0, 3)))
        add(sched, action, Trigger(DateTime(2010, 1, 1, 0, 5)))
        run_pending(sched)
        @test n_executed == 0

        dt = dt + Dates.Minute(1)  # 00:01
        println("Clock set to $dt")
        set(clock, dt)
        run_pending(sched)
        @test n_executed == 0

        dt = dt + Dates.Minute(1)  # 00:02
        println("Clock set to $dt")
        set(clock, dt)
        run_pending(sched)
        @test n_executed == 0

        dt = dt + Dates.Minute(1)  # 00:03
        println("Clock set to $dt")
        set(clock, dt)
        run_pending(sched)
        @test n_executed == 1

        dt = dt + Dates.Minute(1)  # 00:04
        println("Clock set to $dt")
        set(clock, dt)
        run_pending(sched)
        @test n_executed == 1

        dt = dt + Dates.Minute(1)  # 00:05
        println("Clock set to $dt")
        set(clock, dt)
        run_pending(sched)
        @test n_executed == 2

    end
end
