# LoopThrottle

[![Build Status](https://travis-ci.org/tkoolen/LoopThrottle.jl.svg?branch=master)](https://travis-ci.org/tkoolen/LoopThrottle.jl)
[![codecov.io](http://codecov.io/github/tkoolen/LoopThrottle.jl/coverage.svg?branch=master)](http://codecov.io/github/tkoolen/LoopThrottle.jl?branch=master)

LoopThrottle is a tiny Julia package that exports the `@throttle` macro, which can be used to
slow down a `for` loop or `while` loop by calling `sleep` at the beginning of each
loop iteration (if necessary), so that a designated variable increases
at a rate of at most `max_rate` (compared to wall time).

## Examples
```julia
x = 0
@throttle t for t = 1 : 0.01 : 2
    x += 1
end max_rate = 2.
```
will finish in approximately 0.5 second.

```julia
x = 0.
@throttle x for i = 0 : 1000
    x += 1e-3
end
```
will use the default `max_rate` value of `1.` and thus finish in approximately 1 second.
```julia
i = 0
@throttle i while i <= 10
    println(i)
    i += 1
end min_sleep_time=1.5 max_rate=1
```
will print the numbers from 0 to 10 at an average rate of one per second, while never
sleeping for less than 1.5 second.
