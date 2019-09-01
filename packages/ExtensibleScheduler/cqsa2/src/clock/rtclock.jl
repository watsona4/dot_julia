import Dates: now


"""
    RealTimeClock(functor::TimeFunc)

A real time clock (system time) which use a `TimeFunc` functor

`real_time_clock` is default system clock. It's using UTC DateTime
"""
struct RealTimeClock <: AbstractClock
    func::TimeFunc
end

real_time_clock = RealTimeClock(UTCDateTimeFunc)

"""
    now(clock::RealTimeClock)

Return current instant from a (system) clock
"""
function now(clock::RealTimeClock)
    clock.func()
end

"""
    set(clock::RealTimeClock, value)

Setting clock to a system clock is not an allowed operation
"""
function set(clock::RealTimeClock, value)
    throw(ClockException("RealTimeClock can't be set"))
end
