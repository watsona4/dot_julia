"""
Abstract type for struct that returns real-time or simulated time
when called (functor)
"""
abstract type TimeFunc end

"""
    UTCDateTimeFuncStruct()

Functor that return real-time as DateTime (UTC) when called
"""
struct UTCDateTimeFuncStruct <: TimeFunc
    func::Function
    args

    UTCDateTimeFuncStruct() = new(now, [Dates.UTC])
end
function (timefunc::UTCDateTimeFuncStruct)()
    timefunc.func(timefunc.args...)
end
UTCDateTimeFunc = UTCDateTimeFuncStruct()


"""
    FloatTimeFuncStruct()

Functor that return real-time as Float when called
"""
struct FloatTimeFuncStruct <: TimeFunc
    func::Function

    FloatTimeFuncStruct() = new(time)
end
function (timefunc::FloatTimeFuncStruct)()
    timefunc.func()
end
FloatTimeFunc = FloatTimeFuncStruct()


"""
Default time function
"""
global _time = UTCDateTimeFunc

# Time as Float64
#_time = FloatTimeFunc

# Time as DateTime (UTC)
#_time = UTCDateTimeFunc
