using Test
using Dates
using ExtensibleScheduler


@testset "TriggerIterator" begin
    dt_start = DateTime(2010, 1, 1, 20, 30)

    @testset "InfiniteTrigger FiniteIterator" begin
        n_trig = -1
        n_itr = 4
        trigger = Trigger(Dates.Time(20, 30), n=n_trig)
        itr = iterate(trigger, dt_start; n=n_itr)

        @test_throws MethodError length(trigger)
        @test length(itr) == n_itr

        n_triggered = 0
        for dt in itr
            #println(dt)
            n_triggered += 1
        end
        @test n_triggered == 4
    end
    @testset "FiniteTrigger FiniteIterator" begin
        n_trig = 3
        n_itr = 4
        trigger = Trigger(Dates.Time(20, 30), n=n_trig)
        itr = iterate(trigger, dt_start; n=n_itr)

        @test length(trigger) == n_trig
        @test length(itr) == min(n_trig, n_itr)

        n_triggered = 0
        for dt in itr
            n_triggered += 1
        end
        @test n_triggered == min(n_trig, n_itr)
    end

    @testset "FiniteTrigger InfiniteIterator" begin
        n_trig = 3
        n_itr = -1
        trigger = Trigger(Dates.Time(20, 30), n=n_trig)
        dt_start = DateTime(2010, 1, 1, 20, 30)
        itr = iterate(trigger, dt_start; n=n_itr)

        @test length(trigger) == n_trig
        @test length(itr) == n_trig

        n_triggered = 0
        for dt in itr
            println(dt)
            n_triggered += 1
        end
        @test n_triggered == n_trig
    end

    @testset "InfiniteTrigger InfiniteIterator" begin
        n_trig = -1
        n_itr = -1
        trigger = Trigger(Dates.Time(20, 30), n=n_trig)
        dt_start = DateTime(2010, 1, 1, 20, 30)
        itr = iterate(trigger, dt_start; n=n_itr)

        @test_throws MethodError length(trigger)
        @test_throws MethodError length(itr)

        n_stop = 10
        n_triggered = 0
        for (i, dt) in enumerate(itr)
            n_triggered += 1
            if i == n_stop
                break
            end
        end
        @test n_triggered == n_stop
    end

end