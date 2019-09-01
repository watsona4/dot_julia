"""
Sends all log records to the global logger on the master process. An additional
keyword argument, `_pid=myid()` is also passed.
"""
struct WorkerLogger <: AbstractLogger end
function WorkerLogger(logger::AbstractLogger)
    if myid() == 1
        return logger
    end

    return WorkerLogger()
end

function recieve_log_msg(pid, args...; kwargs...)
    handle_message(global_logger(), args...; _pid=pid, kwargs...)
    nothing
end

function handle_message(logger::WorkerLogger, args...; kwargs...)
    remotecall_fetch(EnhancedLogging.recieve_log_msg, 1, myid(), args...; kwargs...)
    nothing
end

shouldlog(::WorkerLogger, args...) = true
min_enabled_level(::WorkerLogger) = Base.CoreLogging.BelowMinLevel
catch_exceptions(::WorkerLogger) = true
