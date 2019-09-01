import Base: IteratorSize, HasLength, IsInfinite, length


struct FinitePeriodTrigger <: AbstractFiniteTrigger
    td::Dates.Period
    n::Int
end

struct InfinitePeriodTrigger <: AbstractInfiniteTrigger
    td::Dates.Period
end

"""
    PeriodTrigger(t::Dates.Time[, n=number_of_times])

A trigger which should trigger a job after a given period (`DatePeriod` or `TimePeriod`)

# Optional parameter
- `n=1`: trigger once
- `n=-1` (default): trigger every day indefinitely
- `n=value`: trigger just a number of times
"""
function PeriodTrigger(td; n=-1)
    if n < 0
        InfinitePeriodTrigger(td)
    else
        FinitePeriodTrigger(td, n)
    end
end

"""
    Trigger(td::Dates.Period[, n=number_of_times])

Return an `PeriodTrigger` which should trigger a job after a given period (`DatePeriod` or `TimePeriod`).
"""
Trigger(td::Dates.Period; kwargs...) = PeriodTrigger(td; kwargs...)

function get_next_dt_fire(trigger::Union{FinitePeriodTrigger,InfinitePeriodTrigger}, dt_previous_fire, dt_now)
    if dt_previous_fire == DateTime(0)
        dt_now + trigger.td
    else
        dt_previous_fire + trigger.td
    end
end
