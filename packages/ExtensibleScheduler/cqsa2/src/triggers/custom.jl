struct FiniteCustomTrigger <: AbstractFiniteTrigger
    f::Function
    n::Int
end

struct InfiniteCustomTrigger <: AbstractInfiniteTrigger
    f::Function
end

"""
    CustomTrigger(f::Function[, n=number_of_times])

A trigger which should trigger a job according a function `f`.

It's generally a better idea (cleaner implementation) to write your own 
trigger from  `AbstractTrigger`, `AbstractFiniteTrigger` or `AbstractInfiniteTrigger` 
but passing a function to a `CustomTrigger` can be quite handy

Job can be triggered:

- once (`n=1`)
- a finite number of times (`n=number_of_times`)
- indefinitely (without setting `n`)

# Example

    f = (dt_previous_fire, dt_now) -> dt_now + Dates.Minute(5)
    trigger = CustomTrigger(f)

should run a job every 5 minutes
"""
function CustomTrigger(f; n=-1)
    if n < 0
        InfiniteCustomTrigger(f)
    else
        FiniteCustomTrigger(f, n)
    end
end

"""
    Trigger(f::Function[, n=number_of_times])

Return an `CustomTrigger` which should trigger a job according a function `f`.
"""
Trigger(f::Function; kwargs...) = CustomTrigger(f; kwargs...)

function get_next_dt_fire(trigger::Union{FiniteCustomTrigger,InfiniteCustomTrigger}, dt_previous_fire, dt_now)
    trigger.f(dt_previous_fire, dt_now)
end
