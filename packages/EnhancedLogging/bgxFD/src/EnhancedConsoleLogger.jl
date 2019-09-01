"""
    EnhancedConsoleLogger(stream::IO==stderr; kwargs...)

Replacement for the standard library `ConsoleLogger` that adds several usability
improvements.

# Additional keyword arguments
The `EnhancedConsoleLogger` supports all of the standard keyword arguments accepted
by `ConsoleLogger`. In addition, special behavior is defined for the following arguments:
 *  `_pid`: prints in a column on the top right side of a log message. This keyword is
    used internally by `WorkerLogger` to display the originating process for a
    log message.
 *  `_overwrite`: If `true`, then repetitions of the log message will be printed over to
    avoid filling the screen with log messages.
 *  `progress`: For a progress between 0 and 1, draw a progress bar on the right side
    of the log message.
 *  `_showlocation`: If true, print the location of the log message. Defaults to true for
    `Debug`, `Warning`, and `Error` logs, and to false for `Info` logs.
"""
mutable struct EnhancedConsoleLogger <: AbstractLogger
    stream::IO
    min_level::LogLevel

    width::Int
    show_limited::Bool
    message_limits::Dict{Any, Int}

    last_id::Symbol
    last_length::Int
end
function EnhancedConsoleLogger(stream::IO=stderr; show_limited=true, width=80,
                               min_level::LogLevel=ProgressLevel)
    EnhancedConsoleLogger(stream, min_level, width, show_limited, Dict{Any, Int}(),
                          :nothing, 0)
end

"""
    progress_string(progress, width)

Returns a string with a completion percentage and a progress bar. Uses Unicode characters
to render sub-character progress increments.
"""
function progress_string(progress, width)
    progress_chars = [' ', '▏', '▎', '▍', '▌', '▋',  '▊', '▉', '█']

    progress_bar_width = width - 9
    progress_width = progress_bar_width*progress

    if progress_width >= progress_bar_width
        return @sprintf "%5.1f%% ║%s" 100 '█'^progress_bar_width
    end
    full_blocks = floor(Int, progress_width)
    remaining_width = progress_width - full_blocks
    trailing_char = progress_chars[floor(Int, remaining_width*8)+1]

    blank_blocks = progress_bar_width-full_blocks-1
    blank_blocks < 0 && (blank_blocks = 0)

    @sprintf "%5.1f%% ║%s" progress*100 ('█'^full_blocks)*trailing_char*(' '^blank_blocks)
end

function log_label(level)
    level == Logging.Warn && return "Warning"
    level == ProgressLevel && return "Progress"
    return string(level)
end

function log_color(level)
    color = Logging.default_logcolor(level)
    level == ProgressLevel && (color = :green)
    return color
end

function log_location(mod, group, id, file, line)
    location = ""
    mod !== nothing && (location *= "$mod")
    if file !== nothing
        mod !== nothing && (location *= " ")
        location *= Base.contractuser(file)
        if line !== nothing
            location *= ":$(isa(line, UnitRange) ? "$(first(line))-$(last(line))" : line)"
        end
    end
    return location
end

function log_message(logger::EnhancedConsoleLogger, msg, kwargs)
    msglines = [(indent=0,msg=l) for l in split(chomp(string(msg)), '\n')]
    dsize = displaysize(logger.stream)
    if !isempty(kwargs)
        valbuf = IOBuffer()
        rows_per_value = max(1, dsize[1]/(length(kwargs)+1))
        valio = IOContext(IOContext(valbuf, logger.stream),
                          :displaysize => (rows_per_value, dsize[2]-5),
                          :limit => logger.show_limited)
        for (key,val) in pairs(kwargs)
            key == :progress      && continue
            key == :_pid          && continue
            key == :_overwrite    && continue
            key == :_showlocation && continue
            Logging.showvalue(valio, val)
            vallines = split(String(take!(valbuf)), '\n')
            if length(vallines) == 1
                push!(msglines, (indent=2,msg=SubString("$key = $(vallines[1])")))
            else
                push!(msglines, (indent=2,msg=SubString("$key =")))
                append!(msglines, ((indent=3,msg=l) for l in vallines))
            end
        end
    end

    return msglines
end

function handle_message(logger::EnhancedConsoleLogger, level, message, mod, group,
                        id, file, line; maxlog=nothing, kwargs...)
    if maxlog isa Integer
        remaining = get!(logger.message_limits, id, maxlog)
        logger.message_limits[id] = remaining - 1
        remaining > 0 || return
    end

    label = log_label(level)
    color = log_color(level)
    msglines = log_message(logger, message, kwargs)

    buf = IOBuffer()
    iob = IOContext(buf, logger.stream)

    should_overwrite = get(kwargs, :_overwrite, level == ProgressLevel)
    if should_overwrite && id == logger.last_id
        print(iob, "\u1b[A"^logger.last_length)
    end

    pid_string = haskey(kwargs, :_pid) ? "║"*string(kwargs[:_pid]) : ""
    justify_width = min(logger.width, displaysize(logger.stream)[2])

    i = 1
    print_progress = (level == ProgressLevel)
    print_location = get(kwargs, :_showlocation,
                         level < ProgressLevel || level >= Logging.Warn)
    while i <= length(msglines)
        indent = msglines[i][1]
        msg    = msglines[i][2]
        linewidth = 2
        printstyled(iob, "║ ", bold=true, color=color)

        if i == 1 && !isempty(label)
            printstyled(iob, label, " ", bold=true, color=color)
            linewidth += length(label) + 1
        end
        print(iob, ' '^indent, msg)
        linewidth += indent + length(msg)

        if print_progress
            prog_string = haskey(kwargs, :progress) ? progress_string(kwargs[:progress], 30) : "NO PROGRESS PROVIDED "
            prog_color  = haskey(kwargs, :progress) ? :green : :red
            npad = justify_width - linewidth - length(prog_string) -
                   (i == 1 ? length(pid_string) : 0) - 3

            if npad < 0
                insert!(msglines, i+1, (indent=0,msg=SubString("")))
            else
                printstyled(iob, ' ', '·'^npad, ' ', color=:light_black)
                printstyled(iob, prog_string, color=prog_color, bold=true)
                linewidth += npad + 32

                print_progress = false

                if i == length(msglines) && print_location
                    push!(msglines, (indent=0,msg=SubString("")))
                end
            end
        end

        if i == length(msglines) && print_location
            location = log_location(mod, group, id, file, line)

            npad = justify_width - linewidth - length(location) -
                   (i == 1 ? length(pid_string) : 0) - 4

            if npad < 0
                push!(msglines, (indent=0,msg=SubString("")))
            else
                printstyled(iob, ' ', '·'^npad, ' ', location, color=:light_black)
                linewidth += npad + length(location) + 2

                print_location = false
            end
        end

        npad = max(0, justify_width - linewidth - (i == 1 ? length(pid_string) : 0) - 1)
        printstyled(iob, ' '^npad, bold=true, color=color)
        if i == 1 && pid_string != ""
            printstyled(iob, pid_string, bold=true, color=color)
            linewidth += length(pid_string)
        end
        printstyled(iob, "║", bold=true, color=color)
        println(iob)

        i += 1
    end

    logger.last_id = id
    logger.last_length = length(msglines)
    write(logger.stream, take!(buf))
    nothing
end

shouldlog(::EnhancedConsoleLogger, args...) = true
min_enabled_level(logger::EnhancedConsoleLogger) = logger.min_level
catch_exceptions(::EnhancedConsoleLogger) = false
