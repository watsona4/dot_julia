import Base: IteratorSize, HasLength, IsInfinite, length


"""
`AbstractTrigger` is an abstract type for Triggers

A Trigger define when a job should be run.

`AbstractTrigger` should implement `get_next_dt_fire` function which returns instant at which a job should be run (given current instant `dt_now` and instant when job was previously run (`dt_previous_fire`)
"""
abstract type AbstractTrigger end
abstract type AbstractFiniteTrigger <: AbstractTrigger end
abstract type AbstractInfiniteTrigger <: AbstractTrigger end

"""
NoTrigger define a trigger that never trigger.

It's a useful struct for triggers operations such as applying offset or jitter to a trigger.
"""
struct NoTrigger <: AbstractTrigger
end


function IteratorSize(trigger::AbstractFiniteTrigger)
    HasLength()
end

function IteratorSize(trigger::AbstractInfiniteTrigger)
    IsInfinite()
end

function length(trigger::AbstractFiniteTrigger)
    trigger.n
end

include("instant.jl")
include("time.jl")
include("period.jl")
include("timeframe.jl")
include("offset.jl")
include("jitter.jl")
include("iterator.jl")
include("custom.jl")