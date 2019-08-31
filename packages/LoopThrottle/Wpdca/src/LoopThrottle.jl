__precompile__()

module LoopThrottle

export
    @throttle

function loop_throttle_params(; max_rate = 1., min_sleep_time = 0.01)
    min_sleep_time >= 0.001 || error("min_sleep_time must be at least 0.001")
    Float64(max_rate), Float64(min_sleep_time)
end

"""
    @throttle

Throttle a `for` loop or `while` loop by calling `sleep` at the beginning of each
loop iteration (if necessary), so that a designated variable increases
at a rate of at most `max_rate` (compared to wall time).

The first argument that `@throttle` takes is the variable to be rate-limited. This
variable must be in scope inside the loop body. The second argument is a for loop
or while loop. Optionally, the following keyword arguments may be passed in after
the loop argument:
* `max_rate`: specifies the maximum rate at which the designated variable should
increase. Defaults to `1.`.
* `min_sleep_time`: specifies the minimum time to sleep (in seconds). Defaults to
`0.01`, and must be at least 0.001 (due to the accuracy of the `sleep` function).

# Examples
```julia
x = 0
@throttle t for t = 1 : 0.01 : 2
    x += 1
end max_rate = 2.
```
will finish in approximately 0.5 seconds.

```julia
x = 0.
@throttle x for i = 0 : 10
    x += 0.1
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
"""
macro throttle(t::Symbol, loopexpr::Expr, params::Expr...)
    foreach(params) do expr
        @assert expr.head == :(=)
        @assert expr.args[1] isa Symbol
        expr.head = :kw
        expr.args[2] = esc(expr.args[2])
    end

    setup = quote
        max_rate, min_sleep_time = loop_throttle_params($(params...))
        firstloop = true
        local t0
        local walltime0
    end

    @assert loopexpr.head ∈ (:while, :for)
    loopcondition = loopexpr.args[1]
    loopbody = loopexpr.args[2]
    newloopbody = quote
        if firstloop
            t0 = $(esc(t))
            walltime0 = time()
            firstloop = false
        else
            if !isinf(max_rate)
                Δwalltime = time() - walltime0
                Δt = $(esc(t)) - t0
                sleeptime = Δt / max_rate - Δwalltime
                if sleeptime > min_sleep_time
                    sleep(sleeptime)
                end
            end
        end

        $(esc(loopbody))
    end
    loop = Expr(loopexpr.head, :($(esc(loopcondition))), newloopbody)

    quote
        $setup
        $loop
    end
end

end # module
