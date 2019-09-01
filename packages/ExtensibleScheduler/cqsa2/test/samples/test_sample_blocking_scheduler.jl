using Test
using ExtensibleScheduler

using TimeFrames

@testset "sample blocking scheduler" begin

    # Time as Float
    _time = time

    function print_time_noparam()
        println("From print_time_noparam $(_time())")
    end

    function print_time_args(x)
        println("From print_time_args $(_time()) $x")
    end

    function print_time_kwargs(; a="default")
        println("From print_time_kwargs $(_time()) $a")
    end

    function print_some_times()
        sched = BlockingScheduler()

        println(_time())
        #add(sched, Action(print_time_noparam), Trigger(Dates.Second(1), n=3))
        add(sched, Action(print_time_noparam), Trigger(TimeFrame("1s"), n=3))
        #add(sched, Action(print_time_args, ("positional, argument")), TimeFrame("10s"); priority=2)
        #add(sched, Action(print_time_kwargs; Dict(:a=>"keyword")...), TimeFrame("5s"); priority=1)
        #add(sched, Action(print_time_noparam), TimeFrame("10s"); priority=1)
        run(sched)
        println(_time())

        # try
        #     # start(sched)
        # catch  # KeyboardInterrupt, SystemExit
        #     #...
        # end
    end

    print_some_times()

    @test 1 == 1

end