using Test
using Dates
using ExtensibleScheduler
using TimeFrames


@testset "TimeFrameTrigger" begin
    tf = tf"5Min"
    trigger = Trigger(tf)

    n_executed = 0

    function sample_action()
        n_executed += 1
    end

    dt_start = DateTime(2010, 1, 3, 23, 58)
    dt = dt_start
    clock = SimClock(dt)
    sched = BlockingScheduler(clock=clock, delayfunc=NoSleep)
    action = Action(sample_action)

    add(sched, action, trigger)
    run_pending(sched)
    @test n_executed == 0

    for i in 1:13
        dt += Dates.Minute(1)
        #println("Clock set to $dt")
        set(clock, dt)
        run_pending(sched)
    end

    @test n_executed == 3

end