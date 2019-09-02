module MiniLogging

export get_logger, basic_config

include("Hierarchy.jl")
using .Hierarchy

const LogLevel = Int

const DEFINED_LEVELS = Dict(
    0 => :NOTSET,
    10 => :DEBUG,
    20 => :INFO,
    30 => :WARN,
    40 => :ERROR,
    50 => :CRITICAL,
)

for (value, symbol) in DEFINED_LEVELS
    @eval $symbol = $value
end


mutable struct Handler
    output::IO
    date_format::String
end

mutable struct Logger
    name::String
    level::LogLevel
    handlers::Vector{Handler}
end

function Base.show(io::IO, logger::MiniLogging.Logger)
    level_symbol = get(DEFINED_LEVELS, logger.level, nothing)
    if level_symbol == nothing
        level_str = string(logger.level)
    else
        level_str = string(level_symbol, ":", logger.level)
    end

    if (is_root(logger.name))
        print(io, "RootLogger($level_str)")
    else
        print(io,
            """Logger("$(logger.name)", $level_str)"""
        )
    end
end

Logger(name::String, level::LogLevel) = Logger(name, level, Handler[])

const TREE = Tree()
const ROOT = Logger("", WARN)
const LOGGERS = Dict{String, Logger}("" => ROOT)

is_root(name::String) = name == "" || name == "Main"

get_logger() = ROOT

"""
- `@assert get_logger("") == get_logger() == get_logger("Main")`
"""
function get_logger(name::String)::Logger
    if is_root(name)
        return get_logger()
    end

    if haskey(LOGGERS, name)
        return LOGGERS[name]
    end

    push!(TREE, name)
    logger = Logger(name, NOTSET)
    LOGGERS[name] = logger
    logger
end

get_logger(name) = get_logger(string(name))

is_not_set(logger::Logger) = logger.level == NOTSET

function get_effective_level(logger::Logger)::LogLevel
    logger_name = logger.name
    while !is_root(logger_name)
        if !is_not_set(logger)
            return logger.level
        end
        logger_name = parent_node(TREE, logger.name)
        logger = LOGGERS[logger_name]
    end
    # This is `ROOT`.
    return logger.level
end

is_enabled_for(logger::Logger, level::LogLevel) = level >= get_effective_level(logger)

has_handlers(logger::Logger) = !isempty(logger.handlers)

function get_effective_handlers(logger::Logger)::Vector{Handler}
    logger_name = logger.name
    while !is_root(logger_name)
        if has_handlers(logger)
            return logger.handlers
        end
        logger_name = parent_node(TREE, logger.name)
        logger = LOGGERS[logger_name]
    end
    # This is `ROOT`.
    return logger.handlers
end


function basic_config(level::LogLevel; date_format::String="%Y-%m-%d %H:%M:%S")
    ROOT.level = level
    handler = Handler(stderr, date_format)
    push!(ROOT.handlers, handler)
end

function basic_config(level::LogLevel, file_name::String; date_format::String="%Y-%m-%d %H:%M:%S", file_mode::String="a")
    ROOT.level = level
    f = open(file_name, file_mode)
    handler = Handler(f, date_format)
    push!(ROOT.handlers, handler)
end

write_log(output::T, color::Symbol, msg::AbstractString) where T <: IO = (print(output, msg); flush(output))
write_log(output::Base.TTY, color::Symbol, msg::AbstractString) = Base.printstyled(output, msg, color=color)

function _log(
        logger::Logger, level::LogLevel, color::Symbol,
        msg...
    )
    logger_name = is_root(logger.name) ? "Main" : logger.name
    level_symbol = get(DEFINED_LEVELS, level, nothing)
    if level_symbol == nothing
        level_str = string(level)
    else
        level_str = string(level_symbol)
    end

    for handler in get_effective_handlers(logger)
        t = Libc.strftime(handler.date_format, time())
        s = string(t, ":" , level_str, ":", logger_name, ":" , msg..., "\n")
        write_log(handler.output, color, s)
    end
end


function define_macro(macro_name::Symbol, level::LogLevel, color::Symbol)
    @eval macro $macro_name(logger, msg...)
        level = $level
        # This generates e.g. `:red`.
        color = $(Expr(:quote, color))
        msg = map(esc, msg)
        quote
            logger = $(esc(logger))
            if is_enabled_for(logger, $level)
                _log(logger, $level, $(Expr(:quote, color)), $(msg...))
            end
        end
    end
    callable_macro_name = Symbol("@", macro_name)
    @eval export $callable_macro_name
end


for (macro_name, level, color) in [
        (:debug, DEBUG, :cyan),
        (:info, INFO, :blue),
        (:warn, WARN, :magenta),
        (:error, ERROR, :red),
        (:critical, CRITICAL, :red)
    ]
    define_macro(macro_name, level, color)
end


function define_new_level(
        macro_name::Symbol,
        level::LogLevel,
        color::Symbol=":yellow"
    )
    DEFINED_LEVELS[level] = macro_name
    define_macro(macro_name, level, color)
end




end