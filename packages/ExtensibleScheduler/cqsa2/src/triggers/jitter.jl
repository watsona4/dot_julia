"""
    TriggerJitter(trigger, offset)

or

    TriggerOffset(offset)

A trigger operation that apply [jitter](https://en.wikipedia.org/wiki/Jitter) to instant when a job should be triggered.

Addition `+` and substraction `-` are implemented so it's possible to define a new trigger using

    Trigger("H") + TriggerJitter(Date.Minute(3))

to be able to run a job every hour with a random jitter of 3 minutes.
This is same as:

    TriggerJitter(Trigger("H"), Date.Minute(3))


Randomize `next_dt_fire` by adding or subtracting a random value (the jitter). If the
resulting DateTime is in the past, returns the initial `next_dt_fire` without jitter.

next_dt_fire - jitter <= result <= next_dt_fire + jitter
"""
struct TriggerJitter
    trigger::AbstractTrigger
    jitter

    TriggerJitter() = error("ToDo")
end
