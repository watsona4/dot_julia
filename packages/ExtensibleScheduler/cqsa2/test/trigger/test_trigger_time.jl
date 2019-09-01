using Test
using Dates
using ExtensibleScheduler
using ExtensibleScheduler: FiniteTimeTrigger, InfiniteTimeTrigger, get_next_dt_fire
using Base: IteratorSize, HasLength, IsInfinite, length


@testset "TimeTrigger" begin
    @testset "one shot" begin
        @testset "trigger" begin
            for (t_fire_at, dt_previous_fire, dt_now, dt_next_fire) in [
                (Dates.Time(20, 30), DateTime(0), DateTime(2008, 5, 4, 12, 0), DateTime(2008, 5, 4, 20, 30)),  # same day
                (Dates.Time(20, 30), DateTime(0), DateTime(2008, 5, 4, 22, 0), DateTime(2008, 5, 5, 20, 30))  # next day
            ]
                trigger = Trigger(t_fire_at, n=1)

                @test trigger isa FiniteTimeTrigger
                @test get_next_dt_fire(trigger, dt_previous_fire, dt_now) == dt_next_fire

                @test IteratorSize(trigger) == HasLength()
                @test length(trigger) == 1
            end
        end

        @testset "sample" begin
            n_executed = 0

            function sample_action()
                n_executed += 1
            end
            trigger = Trigger(Dates.Time(12, 00), n=1)
            dt_start = DateTime(2010, 1, 1, 0, 0)
            dt = dt_start
            clock = SimClock(dt)
            sched = BlockingScheduler(clock=clock, delayfunc=NoSleep)
            action = Action(sample_action)

            add(sched, action, trigger)
            run_pending(sched)
            @test n_executed == 0

            dt = DateTime(2010, 1, 1, 11, 59)
            #println("Clock set to $dt")
            set(clock, dt)
            run_pending(sched)
            @test n_executed == 0

            dt = DateTime(2010, 1, 1, 12, 00)
            #println("Clock set to $dt")
            set(clock, dt)
            run_pending(sched)
            @test n_executed == 1  # run action once

            dt = DateTime(2010, 1, 1, 12, 01)
            #println("Clock set to $dt")
            set(clock, dt)
            run_pending(sched)
            @test n_executed == 1

            dt = DateTime(2010, 1, 2, 12, 00)
            #println("Clock set to $dt")
            set(clock, dt)
            run_pending(sched)
            @test n_executed == 1  # don't run action again

            dt = DateTime(2010, 1, 3, 12, 00)
            #println("Clock set to $dt")
            set(clock, dt)
            run_pending(sched)
            @test n_executed == 1  # don't run action again
        end
    end



    @testset "n shots" begin
        @testset "trigger" begin
            (t_fire_at, dt_previous_fire, dt_now, dt_next_fire) = (Dates.Time(20, 30), DateTime(0), DateTime(2008, 5, 4, 12, 0), DateTime(2008, 5, 4, 20, 30))

            n = 4
            trigger = Trigger(t_fire_at, n=n)

            @test trigger isa FiniteTimeTrigger
            @test get_next_dt_fire(trigger, dt_previous_fire, dt_now) == dt_next_fire

            @test IteratorSize(trigger) == HasLength()
            @test length(trigger) == n
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
            trigger = Trigger(Dates.Time(12, 00), n=2)
            add(sched, action, trigger)
            run_pending(sched)
            @test n_executed == 0

            dt = DateTime(2010, 1, 1, 11, 59)
            #println("Clock set to $dt")
            set(clock, dt)
            run_pending(sched)
            @test n_executed == 0
        
            dt = DateTime(2010, 1, 1, 12, 00)
            #println("Clock set to $dt")
            set(clock, dt)
            run_pending(sched)
            @test n_executed == 1  # run action once
        
            dt = DateTime(2010, 1, 1, 12, 01)
            #println("Clock set to $dt")
            set(clock, dt)
            run_pending(sched)
            @test n_executed == 1
        
            dt = DateTime(2010, 1, 2, 12, 00)
            #println("Clock set to $dt")
            set(clock, dt)
            run_pending(sched)
            @test n_executed == 2  # run action twice
        
            dt = DateTime(2010, 1, 3, 12, 00)
            #println("Clock set to $dt")
            set(clock, dt)
            run_pending(sched)
            @test n_executed == 2  # don't run action again
        end
    end


    @testset "infinite shots" begin
        @testset "trigger" begin
            (t_fire_at, dt_previous_fire, dt_now, dt_next_fire) = (Dates.Time(20, 30), DateTime(0), DateTime(2008, 5, 4, 12, 0), DateTime(2008, 5, 4, 20, 30))

            trigger = Trigger(t_fire_at)

            @test trigger isa InfiniteTimeTrigger
            @test get_next_dt_fire(trigger, dt_previous_fire, dt_now) == dt_next_fire

            @test IteratorSize(trigger) == IsInfinite()
            @test_throws MethodError length(trigger)
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
            trigger = Trigger(Dates.Time(12, 00))
            add(sched, action, trigger)
            run_pending(sched)
            @test n_executed == 0

            dt = DateTime(2010, 1, 1, 12, 00)
            for i in 1:100
                set(clock, dt)
                run_pending(sched)
                @test n_executed == i  # run action indefinitely
                dt += Dates.Day(1)
            end
        end
    end


end