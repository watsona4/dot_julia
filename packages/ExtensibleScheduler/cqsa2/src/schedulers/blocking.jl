import Base: sleep
using Dates: now


"""
    BlockingScheduler(; clock=real_time_clock, delayfunc=_sleep, jobconfig=JobConfig())

`BlockingScheduler` is the simplest scheduler.
It implements `AbstractScheduler`.

This is a monothread implementation of scheduling job.

# Optional arguments
- `clock::AbstractClock`: clock that will be used by scheduler (it's by default `real_time_clock`, which is system UTC time but a `SimClock` struct can also be passed for simulation purpose).
- `delayfunc::DelayFunc`: functor which is responsible (when called) of waiting until next task should be fired (`_sleep` is used by default but a `NoSleep` struct can also be passed for simulation purpose).
- `jobconfig::JobConfig`: job configuration default settings (`misfire_grace_period`...)
"""
mutable struct BlockingScheduler <: AbstractScheduler
    id::String
    clock::AbstractClock
    delayfunc::DelayFunc
    jobstore::AbstractJobStore
    executor::AbstractExecutor
    jobconfig::JobConfig
    running::Bool

    function BlockingScheduler(; clock=real_time_clock, delayfunc=_sleep, jobconfig=JobConfig())
        id = get_scheduler_id()
        jobstore = MemoryJobStore()
        executor = DebugExecutor()
        jobconfig = JobConfig()
        running = true
        now_ = now(clock)
        println("[*] $now_ Init scheduler $id")
        new(id, clock, delayfunc, jobstore, executor, jobconfig, running)
    end
end

"""
    isrunning(sched)

Return `true` when a scheduler named `sched` is running.
"""
isrunning(sched::BlockingScheduler) = sched.running


"""
    isstopped(sched)

Return `true` when a scheduler named `sched` is stopped.
"""
isstopped(sched::BlockingScheduler) = !isrunning(sched)

"""
    JobStore(sched)

Return `jobstore` of a scheduler named `sched`.
"""
JobStore(sched::BlockingScheduler) = sched.jobstore

"""
    Executor(sched)


Return `executor` of a scheduler named `sched`.
"""
Executor(sched::BlockingScheduler) = sched.executor

"""
    sleep(sched, args...; kwargs...)

Block the scheduler for a specified delay.
"""
sleep(sched::BlockingScheduler, args...; kwargs...) = sched.delayfunc(args...; kwargs...)


"""
    run_pending(sched)

Run pending tasks of a scheduler `sched`.

This function should be called instead of `run` when using scheduler in simulation mode.
"""
function run_pending(sched::BlockingScheduler)
    jobstore = JobStore(sched)
    executor = Executor(sched)
    if length(jobstore) > 0
        job = peek(jobstore)
        now_ = now(sched.clock)
        if job.dt_next_fire > now_
            duration = job.dt_next_fire - now_
            println("[ ] $now_ Sleep $duration until job $(job.id) execution")
            sleep(sched, duration)
        else  # job.dt_next_fire <= now_
            job = dequeue!(jobstore)
            job.n_triggered += 1
            if now_ - job.dt_next_fire <= job.config.misfire_grace_period
                println("[*] $now_ RUNNING $(job.id)")
                dump(job)                
                run(executor, job)
                sleep(sched, 0)
            else
                println("[x] $now_ Can't execute job $(job.id) (beyond misfire grace period)")
            end
            update(jobstore, job, now_)
        end
    end
end

"""
    run(sched)

Run (in a blocking loop) a scheduler named `sched`.
"""
function run(sched::BlockingScheduler)
    now_ = now(sched.clock)
    println("[*] $now_ Running scheduler $(sched.id)")
    while(isrunning(sched))
        if isempty(JobStore(sched))
            shutdown(sched)
        else
            run_pending(sched)
        end
    end
    now_ = now(sched.clock)
    println("[*] $now_ Scheduler $(sched.id) stopped")
end

"""
    add(sched, action, trigger; name=DEFAULT_JOB_NAME, priority=DEFAULT_PRIORITY)


Schedule when an `Action` named `action` should be triggered (according `trigger`).
"""
function add(sched::AbstractScheduler, action::Action, trigger::AbstractTrigger; name=DEFAULT_JOB_NAME, priority=DEFAULT_PRIORITY)
    if isstopped(sched)
        error("Job can't be add to a scheduler which is stopped")
    end
    jobstore = JobStore(sched)
    job_id = get_job_id(jobstore)
    dt_created = now(sched.clock)
    dt_updated = dt_created
    dt_next_fire = DateTime(0)
    n_triggered = 0
    job = Job(job_id, action, trigger, name, priority, dt_created, dt_updated, dt_next_fire, n_triggered, sched.jobconfig)
    push!(jobstore, job)
end

function add(sched::AbstractScheduler, action::Action, trigger; name=DEFAULT_JOB_NAME, priority=DEFAULT_PRIORITY, n=-1)
    add(sched, action, Trigger(trigger, n=n); name=name, priority=priority)
end

"""
    shutdown(sched)

Shutdown scheduler `sched`.
"""
function shutdown(sched::BlockingScheduler)
    sched.running = false
    now_ = now(sched.clock)
    println("[*] $now_ Stopping scheduler $(sched.id)")
end