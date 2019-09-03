"""
A generally useful event scheduler class.
Each instance of this class manages its own queue.
No multi-threading is implied; you are supposed to hack that
yourself, or use a single instance per application.
Each instance is parametrized with two functions, one that is
supposed to return the current time, one that is supposed to
implement a delay.    You can implement real-time scheduling by
substituting time and sleep from built-in module time, or you can
implement simulated time by writing your own functions.    This can
also be used to integrate scheduling with STDWIN events; the delay
function is allowed to modify the queue.    Time can be expressed as
integers or floating point numbers, as long as it is consistent.
Events are specified by tuples (time, priority, action, argument, kwargs).
As in UNIX, lower priority numbers mean higher priority; in this
way the queue can be maintained as a priority queue.    Execution of the
event means calling the action function, passing it the argument
sequence in "argument" (remember that in Python, multiple function
arguments are be packed in a sequence) and keyword parameters in "kwargs".
The action function may be an instance method so it
has another way to reference private data (besides global variables).
"""
module Sched

    export Scheduler, enter, enterabs, cancel, queue
    export FloatTimeFunc, UTCDateTimeFunc
    # Base exports: run, isempty
    import Base: run, isempty

    using DataStructures: PriorityQueue, peek, dequeue!, dequeue_pair!
    using Dates

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

    """
        Event(time_, priority, action, args...; kwargs...)

    Event structure

     - `time_`: Numeric type compatible with the return value of the timefunc function passed to the constructor.'
     - `priority`: Events scheduled for the same time will be executed in the order of their priority.
     - `action`: Executing the event means executing action(args...; kwargs...)
     - `args`: args is a sequence holding the positional arguments for the action.
     - `kwargs`: kwargs is a dictionary holding the keyword arguments for the action.

    """
    struct Event
        time_ 
        priority
        action
        args
        kwargs

        Event(time_, priority, action, args...; kwargs...) = new(time_, priority, action, args, kwargs)
    end
    run(event::Event) = event.action(event.args...; event.kwargs...)

    """
        Scheduler(; timefunc=_time, delayfunc=sleep)

    Initialize a new Scheduler instance, passing optionaly
    the time and delay functions

    The scheduler struct defines a generic interface to scheduling events. 
    It needs two functions to actually deal with the “outside world”

    - The `timefunc` should be callable without arguments, and return a number (the “time”, in any units whatsoever). `timefunc` default is `UTCDateTimeFunc`.

    - The `delayfunc` function should be callable with one argument, compatible  with the output of `timefunc`, and should delay that many time units. delayfunc  will also be called with the argument 0 after each event is run to allow other threads an opportunity to run in multi-threaded applications.
    """
    struct Scheduler
        timefunc::TimeFunc
        delayfunc::Function

            _queue::PriorityQueue
            _lock::ReentrantLock

            function Scheduler(; timefunc=_time, delayfunc=sleep)
                q = PriorityQueue{Event, Priority}(Base.Order.Reverse)
                l = ReentrantLock()
                new(timefunc, delayfunc, q, l)
            end
    end

    """
        Priority(time_, priority)

    Priority of events
    """
    struct Priority
        time_
        priority
    end
    function Base.isless(p1::Sched.Priority, p2::Sched.Priority)
        if p1.time_ > p2.time_
            true
        elseif p1.time_ < p2.time_
            false
        else
            p1.priority > p2.priority
        end
    end

    """
        enterabs(sched, time_, priority, action, args...; kwargs...)

    Enter a new event in the queue at an absolute time.
    Returns an ID for the event which can be used to remove it,
    if necessary.
    """
    function enterabs(sched::Scheduler, time_, priority, action, args...; kwargs...)
        #println("enterabs $sched $time_ $priority $action with args=$args kwargs=$kwargs")
        event = Event(time_, priority, action, args...; kwargs...)
        l = sched._lock
        lock(l)
        try
            sched._queue[event] = Priority(time_, priority)
        finally
            unlock(sched._lock)
        end
        event # The ID
    end

    """
        enter(sched, delay, priority, action, args...; kwargs...)

    Enter a new event in the queue at a relative time.
    A variant of enterabs that specifies the time as a relative time.
    This is actually the more commonly used interface.
    """
    function enter(sched::Scheduler, delay, priority, action, args...; kwargs...)
        next_time = sched.timefunc() + delay
        event = enterabs(sched, next_time, priority, action, args...; kwargs...)
        event
    end

    """
        run(sched; blocking=true)

    Execute events until the queue is empty.
    If blocking is False executes the scheduled events due to
    expire soonest (if any) and then return the deadline of the
    next scheduled call in the scheduler.
    When there is a positive delay until the first event, the
    delay function is called and the event is left in the queue;
    otherwise, the event is removed from the queue and executed
    (its action function is called, passing it the argument).  If
    the delay function returns prematurely, it is simply
    restarted.
    It is legal for both the delay function and the action
    function to modify the queue or to raise an exception;
    exceptions are not caught but the scheduler's state remains
    well-defined so run() may be called again.
    A questionable hack is added to allow other threads to run:
    just after an event is executed, a delay of 0 is executed, to
    avoid monopolizing the CPU when other threads are also
    runnable.
    """
    function run(sched::Scheduler; blocking=true)
        l = sched._lock
        q = sched._queue
        delayfunc = sched.delayfunc
        timefunc = sched.timefunc
        while(true)
            lock(l)
            if length(q) == 0
                break
            end
            next_event, priority = peek(q)
            now_ = timefunc()
            if next_event.time_ > now_
                delay = true
            else
                delay = false
                event = dequeue!(q)
            end
            unlock(l)
            if delay
                if !blocking
                    return next_event.time_ - now_
                end
                delayfunc(next_event.time_ - now_)
            else
                run(event)
                delayfunc(0)     # Let other threads run
            end
        end
    end

    """
        cancel(sched, event)

    Remove an event from the queue.
    This must be presented the ID as returned by enter().
    If the event is not in the queue, this raises ValueError.
    """
    function cancel(sched::Scheduler, event::Event)
        lock(sched._lock)
        dequeue_pair!(sched._queue, event)
        unlock(sched._lock)
    end

    """
        isempty(sched) -> Bool

    Check whether the queue is empty.
    """
    function isempty(sched::Scheduler)
        lock(sched._lock)
        _isempty = isempty(sched._queue)
        unlock(sched._lock)
        _isempty
    end

    """
        queue(sched)

    Return an ordered list of upcoming events.
    """
    function queue(sched::Scheduler)
        q = sched._queue
        q2 = deepcopy(q)
        [dequeue!(q) for i in 1:length(q)]
    end

end # module
