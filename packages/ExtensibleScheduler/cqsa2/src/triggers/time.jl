import Base: IteratorSize, HasLength, IsInfinite, length


struct FiniteTimeTrigger <: AbstractFiniteTrigger
    time_fire_at::Dates.Time
    n::Int
end

struct InfiniteTimeTrigger <: AbstractInfiniteTrigger
    time_fire_at::Dates.Time
end

"""
    TimeTrigger(t::Dates.Time[, n=number_of_times])

A trigger which should trigger a job daily at a given time.

# Optional parameter
- `n=1`: trigger once
- `n=-1` (default): trigger every day indefinitely
- `n=value`: trigger just a number of times
"""
function TimeTrigger(time_fire_at; n=-1)
    if n < 0
        InfiniteTimeTrigger(time_fire_at)
    else
        FiniteTimeTrigger(time_fire_at, n)
    end
end

"""
    Trigger(t::Dates.Time[, n=number_of_times])

Return an `TimeTrigger` which should trigger a job daily at a given time (once, a finite number of times or indefinitely).
"""
Trigger(t::Dates.Time; kwargs...) = TimeTrigger(t; kwargs...)

function get_next_dt_fire(trigger::Union{FiniteTimeTrigger,InfiniteTimeTrigger}, dt_previous_fire, dt_now)
    d = Date(dt_now)
    t = Dates.Time(dt_now)
    if trigger.time_fire_at > t
        d + trigger.time_fire_at
    else
        d + trigger.time_fire_at + Dates.Day(1)
    end
end