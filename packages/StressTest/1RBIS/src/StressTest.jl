module StressTest

"""
    dream(seconds)

Like Base.sleep() except maxes out the thread for a specified number of seconds. The minimum dream time is 1
millisecond or input of `0.001`.
"""
function dream(sec::Real)
    sec ≥ 0 || throw(ArgumentError("cannot dream for $sec seconds"))
    t = Timer(sec)
    while isopen(t)
        yield()
    end
    nothing
end

export dream

end # module
