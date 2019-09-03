struct TimeoutException
    duration
end

function Base.showerror(io::IO, te::TimeoutException)
    print(io, "TimeoutException: Operation did not finish in ", te.duration)

    if !isa(te.duration, Period)
        print(io, " seconds")
    end
end

function asynctimedwait(fn, secs; kill=false)
    t = @async fn()
    timedwait(() -> istaskdone(t), secs)

    if istaskdone(t)
        fetch(t)
        return true
    else
        if kill
            Base.throwto(t, TimeoutException(secs))
        end

        return false
    end
end
