using Test
using Dates
using ExtensibleScheduler
using ExtensibleScheduler: TriggerOffset, get_next_dt_fire


@testset "TriggerOffset" begin
    @testset "+" begin
        for (t_fire_at, offset, dt_previous_fire, dt_now, dt_next_fire) in [
            (DateTime(2009, 7, 6), Dates.Minute(1), DateTime(0), DateTime(2008, 5, 4), DateTime(2009, 7, 6, 0, 1))
        ]
            trigger = TriggerOffset(Trigger(t_fire_at), offset)
            @test get_next_dt_fire(trigger, dt_previous_fire, dt_now) == dt_next_fire

            trigger = Trigger(t_fire_at) + TriggerOffset(offset)
            @test get_next_dt_fire(trigger, dt_previous_fire, dt_now) == dt_next_fire

            trigger = TriggerOffset(offset) + Trigger(t_fire_at)
            @test get_next_dt_fire(trigger, dt_previous_fire, dt_now) == dt_next_fire
        end
    end

    @testset "-" begin
        for (t_fire_at, offset, dt_previous_fire, dt_now, dt_next_fire) in [
            (DateTime(2009, 7, 6), Dates.Minute(1), DateTime(0), DateTime(2008, 5, 4), DateTime(2009, 7, 5, 23, 59))
        ]
            trigger = Trigger(t_fire_at) - TriggerOffset(offset)
            @test get_next_dt_fire(trigger, dt_previous_fire, dt_now) == dt_next_fire

            trigger = TriggerOffset(offset) - Trigger(t_fire_at)
            @test get_next_dt_fire(trigger, dt_previous_fire, dt_now) == dt_next_fire
        end
    end
end
