import Base: isless

const DEFAULT_PRIORITY = 0


"""
    Priority(time_, priority)

Priority of events.

Comparison is first done by time, and after (if same time)
using priority value.

As in UNIX, lower priority numbers mean higher priority.
"""
struct Priority
    time_
    priority
end

function isless(p1::Priority, p2::Priority)
    if p1.time_ > p2.time_
        true
    elseif p1.time_ < p2.time_
        false
    else
        p1.priority > p2.priority
    end
end
