module IOLogging

using Base.CoreLogging
using Base.CoreLogging: AbstractLogger, LogLevel, Debug, Info, Warn, Error, shouldlog, min_enabled_level, catch_exceptions, handle_message
using Dates

export IOLogger, FileLogger

"""
Abstract supertype of all loggers contained in this package.

A logger subtyping this logger should have the following fields:

 * logIOs::Dict{LogLevel, T} where {T <: IO}
 * messageLimits::Dict{Any, Int}

This will be enforced once interfaces are available.
"""
abstract type _iologger <: AbstractLogger end
# TODO: Add interface implementation here once they are available

"""
A generic logger for logging to any `IO`. Does not flush, as flushing is not a general IO operation. Also does not close the given IO.

    IOLogger(logIOs = Dict(Info => stdout))

Logs logging events with LogLevel greater than or equal to `Info` to stdout, should no `logIOs` be given. In case two LogLevels are present, e.g. `Info` and `Error`, all logging events from `Info` up to (but excluding) `Error` will be logged to the stream given by `Info`. `Error` and above will be logged to the stream given by `Error`. It is possible to "clamp" logging events, by providing an upper bound that's logging to `devnull`. Beware, as the message will still be composed before writing to the actual stream (no hotwiring).

By default, exceptions occuring during logging are not caught. This is expected to change in the future, once it's decided how exceptions during logging should be handled.
"""
struct IOLogger <: _iologger
    logIOs::Dict{LogLevel, T} where {T <: IO}
    messageLimits::Dict{Any, Int}

    IOLogger(logIOs::Dict{LogLevel, Q} = Dict(Info => stdout)) where {Q <: IO} = new(logIOs, Dict{Any,Int}())
end

CoreLogging.shouldlog(logger::T, level, _module, group, id) where {T <: _iologger} = level >= min_enabled_level(logger)

CoreLogging.min_enabled_level(logger::T) where {T <: _iologger} = minimum(collect(keys(logger.logIOs)))

# TODO: Make a decision on this. Stay false for now.
CoreLogging.catch_exceptions(logger::T) where {T <: _iologger} = false

function getIO(logger::T, level::LogLevel) where {T <: _iologger}
    posIOs = filter(l -> l[1] <= level, collect(logger.logIOs))
    if !isempty(posIOs)
        sort(posIOs, by = x -> x[1], rev = true)[1][2]
    else
        devnull
    end
end

function checkLimits(logger::T, id, maxlog) where {T <: _iologger}
    if maxlog != nothing && maxlog isa Integer
        # println(id) # REMOVEME: uncomment for manual id checking
        rem = get!(logger.messageLimits, id, maxlog)
        logger.messageLimits[id] = rem - 1
        rem > 0
    else
        true
    end
end

CoreLogging.handle_message(logger::T,
                        level,
                        message,
                        _module,
                        group,
                        id,
                        file,
                        line;
                        maxlog = nothing,
                        kwargs...) where {T <: _iologger} = begin
    # Should we log this?
    if !checkLimits(logger, id, maxlog)
        return
    end

    io = getIO(logger, level)
    log!(io, level, string(message), _module, group, file, line; kwargs...)
    nothing
end

function log!(io::T, level, message, _module, group, file, line; kwargs...) where { T <: IO }
    buffer = IOBuffer()
    context = IOContext(buffer, io)
    logTime = now()
    lines = split(chomp(message), '\n')
    # TODO: Make this format customizable
    prefix = "[$level::$logTime]"
    locString = "$_module@$file:$line"
    if length(lines) > 1
        println(context, prefix, ' ', locString)
        for l in lines
            println(context, prefix, "  ", l)
        end
        for (key, value) in kwargs
            println(context, prefix, "    ", key, " = ", value)
        end
    else
        println(context, prefix, "  ", locString, " - ", lines[1])
        for (key, value) in kwargs
            println(context, prefix, "    ", key, " = ", value)
        end
    end
    write(io, take!(buffer))
    nothing
end

include("FileLogger.jl")

end # module
