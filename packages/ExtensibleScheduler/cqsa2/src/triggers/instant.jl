import Base: IteratorSize, HasLength, length

"""
    InstantTrigger(dt::DateTime)

A trigger which should trigger job at a given instant (a given `DateTime` for example)
"""
struct InstantTrigger <: AbstractTrigger
    dt_fire_at::DateTime
end

IteratorSize(trigger::InstantTrigger) = HasLength()
length(trigger::InstantTrigger) = 1


"""
    Trigger(dt::DateTime)

Return an `InstantTrigger` which should trigger job at a given `DateTime` `dt`
"""
Trigger(dt::DateTime) = InstantTrigger(dt)


"""
    Trigger(d::Date)

Return an `InstantTrigger` which should trigger job at a given `Date` `d`(at midnight)
"""
Trigger(d::Date) = InstantTrigger(DateTime(d))


"""
    get_next_dt_fire(trigger, dt_previous_fire, dt_now)

Return instant at which a job should be run (given current instant `dt_now` and instant when job was previously run (`dt_previous_fire`)
"""
function get_next_dt_fire(trigger::InstantTrigger, dt_previous_fire, dt_now)
    if dt_previous_fire == DateTime(0)
        trigger.dt_fire_at
    else
        DateTime(0)
    end
end
