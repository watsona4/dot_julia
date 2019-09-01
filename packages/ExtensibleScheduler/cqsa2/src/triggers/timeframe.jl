import Base: IteratorSize, IsInfinite, length


using TimeFrames
using TimeFrames: tonext


struct FiniteTimeFrameTrigger <: AbstractFiniteTrigger
    tf::TimeFrame
    n::Int
end

struct InfiniteTimeFrameTrigger <: AbstractInfiniteTrigger
    tf::TimeFrame
end

"""
    TimeFrameTrigger(tf::TimeFrame)

A trigger which should trigger a job at a given instant according timeframe periodicity (from [TimeFrames.jl](https://github.com/femtotrader/TimeFrames.jl))

# Example

    TimeFrameTrigger("H")

should run a job every hour
"""
function TimeFrameTrigger(tf; n=-1)
    if n < 0
        InfiniteTimeFrameTrigger(tf)
    else
        FiniteTimeFrameTrigger(tf, n)
    end
end

"""
    Trigger(tf::TimeFrame[, n=number_of_times])

Return an `TimeFrameTrigger` which should trigger a job at a given instant according timeframe periodicity. (from [TimeFrames.jl](https://github.com/femtotrader/TimeFrames.jl))
"""
Trigger(tf::TimeFrame; kwargs...) = TimeFrameTrigger(tf; kwargs...)

function get_next_dt_fire(trigger::Union{FiniteTimeFrameTrigger,InfiniteTimeFrameTrigger}, dt_previous_fire, dt_now)
    tonext(trigger.tf, dt_now)
end
