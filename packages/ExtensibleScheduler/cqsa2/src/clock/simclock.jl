"""
    SimClock(initial_value)

A simulated clock (for simulation or testing purpose)
"""
mutable struct SimClock <: AbstractClock
    value
end

"""
    now(clock::RealTimeClock)

Return current instant from a simulated clock (for simulation or testing purpose)
"""
function now(clock::SimClock)
    clock.value
end

"""
    set(clock::SimClock, new_value)

Set time (with `new_value` of a simulated clock
"""
function set(clock::SimClock, value)
    if value > clock.value
        clock.value = value
    else
        throw(ClockException("time must be ascending"))
    end
end
