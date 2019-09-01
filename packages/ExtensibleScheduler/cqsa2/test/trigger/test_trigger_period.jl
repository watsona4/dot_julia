using Test
using Dates
using ExtensibleScheduler

@testset "PeriodTrigger" begin
    @testset "TimeTrigger" begin
        td = Dates.Minute(5)
        trigger = Trigger(td)

        n_executed = 0

        function sample_action()
            n_executed += 1
        end
        trigger = Trigger(td)
        dt_start = DateTime(2010, 1, 1, 0, 0)
        dt = dt_start
        clock = SimClock(dt)
        sched = BlockingScheduler(clock=clock, delayfunc=NoSleep)
        action = Action(sample_action)

        add(sched, action, trigger)
        run_pending(sched)
        @test n_executed == 0

        for i in 1:11
            dt += Dates.Minute(1)
            #println("Clock set to $dt")
            set(clock, dt)
            run_pending(sched)
        end

        @test n_executed == 2

    end

    @testset "DateTrigger" begin
        td = Dates.Month(1)

        trigger = Trigger(td)

        n_executed = 0

        function sample_action()
            n_executed += 1
        end
        trigger = Trigger(td)
        dt_start = DateTime(2010, 1, 1, 0, 0)
        dt = dt_start
        clock = SimClock(dt)
        sched = BlockingScheduler(clock=clock, delayfunc=NoSleep)
        action = Action(sample_action)

        add(sched, action, trigger)
        run_pending(sched)
        @test n_executed == 0

        for i in 1:80
            dt += Dates.Day(1)
            #println("Clock set to $dt")
            set(clock, dt)
            run_pending(sched)
        end
        
        @test n_executed == 2
    end

end