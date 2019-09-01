"""
    DebugExecutor()

`DebugExecutor` is a very basic executor that can
be used with a `BlockingScheduler` (with either real clock or simulated clock)
"""
struct DebugExecutor <: AbstractExecutor
end


"""
    run(executor::DebugExecutor, job::Job)

Run an `Action` attached to a given `Job`
"""
function run(executor::DebugExecutor, job::Job)
    action = job.action
    run(action)
end
