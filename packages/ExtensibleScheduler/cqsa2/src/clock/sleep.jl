"""
Abstract type for struct (functor) that can
block the current task for a specified delay.
"""
abstract type DelayFunc end

"""
    SleepFuncStruct()

A struct that can block (when called) 
the current task for a specified number of seconds.

`SleepFuncStruct` implements `DelayFunc` abstract type.

The minimum sleep time is 1 millisecond or input of 0.001.

`SleepFunc` is an instance of `SleepFuncStruct` 

    SleepFunc(duration)

is same as `sleep(duration)`
"""
struct SleepFuncStruct <: DelayFunc
    func
    SleepFuncStruct() = new(sleep)
end
function (delayfunc::SleepFuncStruct)(args...)
    delayfunc.func(args...)
end
SleepFunc = SleepFuncStruct()


"""
    NoSleepStruct()

`NoSleepStruct` implements `DelayFunc` abstract type.

`NoSleep` is an instance of `NoSleepStruct`

When called `NoSleep`, doesn't do anything.

This is simply a workaround for simulating a scheduler waiting 
for next job to be processed.
"""
struct NoSleepStruct <: DelayFunc
end
function (delayfunc::NoSleepStruct)(args...)
end
NoSleep = NoSleepStruct()


"""
Default sleep function
"""
_sleep = SleepFunc
