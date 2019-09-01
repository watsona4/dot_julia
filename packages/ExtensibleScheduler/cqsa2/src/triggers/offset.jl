import Base: +, -

"""
    TriggerOffset(trigger, offset)

or

    TriggerOffset(offset)

A trigger operation to shift instant when a job should be triggered (adding an offset)

Addition `+` and substraction `-` are implemented so it's possible to define a new trigger using

    Trigger("H") + TriggerOffset(Date.Minute(3))

to be able to run a job every hour at 3 minutes after round after.

This is same as:

    TriggerOffset(Trigger("H"), Date.Minute(3))
"""
struct TriggerOffset
    trigger::AbstractTrigger
    offset
end
TriggerOffset(offset) = TriggerOffset(NoTrigger(), offset)


function get_next_dt_fire(trigger::TriggerOffset, dt_previous_fire, dt_now)
    get_next_dt_fire(trigger.trigger, dt_previous_fire, dt_now) + trigger.offset
end

function +(trigger::AbstractTrigger, toffset::TriggerOffset)
    if !(toffset.trigger isa NoTrigger)
        error("toffset.trigger must be NoTrigger")
    end
    TriggerOffset(trigger, toffset.offset)
end
+(toffset::TriggerOffset, trigger::AbstractTrigger) = +(trigger, toffset)

function -(trigger::AbstractTrigger, toffset::TriggerOffset)
    toffset = TriggerOffset(toffset.trigger, -toffset.offset)
    trigger + toffset
end
-(toffset::TriggerOffset, trigger::AbstractTrigger) = -(trigger, toffset)
