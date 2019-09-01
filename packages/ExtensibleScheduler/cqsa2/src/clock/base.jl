include("time.jl")
include("sleep.jl")


"""
`AbstractClock` is an abstract type for clocks

Clocks return instant (`DateTime`) when asked using `now(clock)`

Clock can be real (ie using system time) but can also be fake
(for simulation purpose).

Time can be set on a simulutated clock using `set(clock, new_datetime)`
"""
abstract type AbstractClock end


"""
An exception that a clock can throw.

Generally a clock run an exception when user is trying to set time
on a system clock (which is not allowed).
"""
struct ClockException <: Exception
    s
end

include("rtclock.jl")
include("simclock.jl")