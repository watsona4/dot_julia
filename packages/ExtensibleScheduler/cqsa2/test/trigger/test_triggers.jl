using Test
using ExtensibleScheduler
using ExtensibleScheduler: InstantTrigger, TimeTrigger, get_next_dt_fire
using Base: IteratorSize, HasLength, IsInfinite, length
using ExtensibleScheduler: TriggerOffset
using ExtensibleScheduler: iterate


@testset "Triggers" begin

    include("test_trigger_instant.jl")
    include("test_trigger_time.jl")
    include("test_trigger_period.jl")
    include("test_trigger_offset.jl")
    include("test_trigger_jitter.jl")
    include("test_trigger_timeframe.jl")
    include("test_trigger_cron.jl")
    include("test_trigger_iterator.jl")
    include("test_trigger_custom.jl")

end