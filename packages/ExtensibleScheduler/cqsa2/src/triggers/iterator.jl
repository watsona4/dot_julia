import Base: iterate

"""
    iterate(trigger, dt[, n=number_of_times])


Iterate from instant `dt` using trigger with a given iteration number `n` 
if `n < 0` (`-1` by default), it iterates indefinitely.

# Usage
```
julia> trigger = Trigger(Dates.Time(20, 30))

julia> for dt in iterate(trigger, DateTime(2020, 1, 1), n=3)
         @show dt
       end
dt = 2020-01-01T20:30:00
dt = 2020-01-02T20:30:00
dt = 2020-01-03T20:30:00

julia> collect(iterate(trigger, DateTime(2020, 1, 1), n=3))
3-element Array{Any,1}:
 2020-01-01T20:30:00
 2020-01-02T20:30:00
 2020-01-03T20:30:00
```
"""
function iterate(trigger::AbstractTrigger, dt; n=-1)
    TriggerIterator(trigger, dt, n)
end

abstract type AbstractTriggerIterator end

struct FiniteTriggerIterator <: AbstractTriggerIterator
    trigger::AbstractTrigger
    dt
    n::Int
end

struct InfiniteTriggerIterator <: AbstractTriggerIterator
    trigger::AbstractTrigger
    dt
end

function TriggerIterator(trigger::AbstractTrigger, dt, n)
    if n < 0
        if IteratorSize(trigger) == IsInfinite()
            InfiniteTriggerIterator(trigger, dt)
        else
            FiniteTriggerIterator(trigger, dt, trigger.n)
        end
    else
        if IteratorSize(trigger) == IsInfinite()
            FiniteTriggerIterator(trigger, dt, n)
        else
            FiniteTriggerIterator(trigger, dt, min(n, trigger.n))
        end
    end
end

function iterate(itr::AbstractTriggerIterator, state=(itr.dt, 0))
    dt_now, i = state
    i >= itr.n && return nothing
    dt_next = get_next_dt_fire(itr.trigger, DateTime(0), dt_now)
    i += 1
    state = dt_next, i
    return (dt_next, state)
end

function iterate(itr::InfiniteTriggerIterator, state=(itr.dt, 0))
    dt_now, i = state
    dt_next = get_next_dt_fire(itr.trigger, DateTime(0), dt_now)
    i += 1
    state = dt_next, i
    return (dt_next, state)
end

IteratorSize(itr::InfiniteTriggerIterator) = IsInfinite()
IteratorSize(itr::FiniteTriggerIterator) = HasLength()

length(itr::FiniteTriggerIterator) = itr.n
