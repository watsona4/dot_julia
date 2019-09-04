using Base.CoreLogging

import Base.CoreLogging: min_enabled_level, shouldlog, handle_message, catch_exceptions

export VisualDLLogger, 
 ScalarLevel, HistogramLevel, EmbeddingLevel, TextLevel, AudioLevel, ImageLevel,
 as_mode, add_component, save,  with_logger,
 set_caption, start_sampling, finish_sampling,
 @log_scalar, @log_histogram, @log_image, @log_text

const ScalarLevel = LogLevel(880)
const HistogramLevel = LogLevel(881)
const EmbeddingLevel = LogLevel(882)
const TextLevel = LogLevel(883)
const AudioLevel = LogLevel(884)
const ImageLevel = LogLevel(885)


"""
`VisualDLLogger` is  a subtype of `AbstractLogger`. And all the necessary interfaces 
are implemented. This means that you can use `Base.CoreLogging.disable_logging`
to control the log level and use the similar grammar like `@info`.

The provided log levels are:

```
const ScalarLevel = LogLevel(880)
const HistogramLevel = LogLevel(881)
const EmbeddingLevel = LogLevel(882)
const TextLevel = LogLevel(883)
const AudioLevel = LogLevel(884)
const ImageLevel = LogLevel(885)
```

which are between the `Info` level(`LogLevel(0)``) and `Warn` level(`LogLevel(1000)`).

There are two members in the `VisualDLLogger`, a `pylogger` which is a wrapper of
the python logger instance, and a `components` which is a `Dict` containing all the
components related to the `logger`.
"""
struct VisualDLLogger <: AbstractLogger
    pylogger::PyObject
    components::Dict{Symbol, PyObject}
end

"""
    VisualDLLogger(log_path, sync_cycle, mode="train")

Create a logger instance. `log_path` is used to specify where to store the log data.
`sync_cycle` specify how often should the system store data into the file system.
Typically adding a record requires 6 operations. System will save the data into
the file system once operations count reaches `sync_cycle`.
"""
function VisualDLLogger(log_path::AbstractString, sync_cycle::Int, mode::AbstractString="train")
    pylogger = LogWriter(log_path, sync_cycle)
    pylogger[:mode](mode)
    VisualDLLogger(pylogger, Dict{Symbol, PyObject}())
end

"""
    as_mode(logger, mode)

Clone a logger and reset the mode.
"""
function as_mode(logger::VisualDLLogger, mode::AbstractString)
    VisualDLLogger(logger.pylogger[:as_mode](mode), Dict{Symbol, PyObject}()) 
end

"""
    set_caption(logger, tag, caption)

Set the caption of a figure.
"""
function set_caption(logger::VisualDLLogger, tag::Symbol, caption::AbstractString)
    logger.components[tag][:set_caption](caption)
end

"""
    start_sampling(logger, tag)

This function is only valid for `@log_image` and `@log_audio`.
"""
function start_sampling(logger::VisualDLLogger, tag::Symbol)
    logger.components[tag][:start_sampling]()
end

"""
    finish_sampling(logger, tag)

This function is only valid for `@log_image` and `@log_audio`.
"""
function finish_sampling(logger::VisualDLLogger, tag::Symbol)
    logger.components[tag][:finish_sampling]()
end

"""
    save(logger)

Although the `logger` will automatically save data when the `sync_cycle`
is reached. It is better to force save in the end.
"""
function save(logger::VisualDLLogger)
    logger.pylogger[:save]()
end

"""
    add_component(logger, level, tag; kwargs...)

Althrough this package will automatically initial a component for you when you
add records to a component for the first time, it is strongly suggested to use
this function to initial a component manually.

For the detail of `kwargs`, please read the [python api](http://visualdl.paddlepaddle.org/docs/develop/visualdl/en/api/write_logs.html)
"""
function add_component(logger::VisualDLLogger, level::LogLevel, tag::Symbol; kwargs...)
    kwargs = Dict(kwargs)
    if level == ScalarLevel
        logger.components[tag] = logger.pylogger[:scalar](string(tag))
    elseif level == HistogramLevel
        logger.components[tag] = logger.pylogger[:histogram](string(tag), get(kwargs, :num_buckets, 10))
    elseif level == EmbeddingLevel
        logger.components[tag] = logger.pylogger[:embedding](string(tag))
    elseif level == TextLevel
        logger.components[tag] = logger.pylogger[:text](string(tag))
    elseif level == AudioLevel
        logger.components[tag] = logger.pylogger[:audio](
            string(tag),
            get(kwargs, :num_samples, 1),
            get(kwargs, :step_cycle, 1))
    elseif level == ImageLevel
        logger.components[tag] = logger.pylogger[:image](
            string(tag),
            get(kwargs, :num_samples, 1),
            get(kwargs, :step_cycle, 1))
    end
end

function add_record(logger::VisualDLLogger, level::LogLevel, tag::Symbol, args)
    if level == ScalarLevel
        logger.components[tag][:add_record](args...)
    elseif level == HistogramLevel
        logger.components[tag][:add_record](args...)
    elseif level == EmbeddingLevel
        logger.components[tag][:add_embeddings_with_word_dict](args...)
    elseif level == TextLevel
        logger.components[tag][:add_record](args...)
    elseif level == AudioLevel
        start_sampling(logger, tag)
        logger.components[tag][:add_sample](args...)
        finish_sampling(logger, tag)
    elseif level == ImageLevel
        start_sampling(logger, tag)
        if args isa Array{T, 3} where T <: Number
            logger.components[tag][:add_sample](size(args), collect(Iterators.flatten(args)))
        else
            logger.components[tag][:add_sample](args...)
        end
        finish_sampling(logger, tag)
    end
end

# interfaces
min_enabled_level(logger::VisualDLLogger) = ScalarLevel
shouldlog(logger::VisualDLLogger, level, _module, group, id) =  ScalarLevel ≤ level ≤ ImageLevel
catch_exceptions(logger::VisualDLLogger) = false

function handle_message(logger::VisualDLLogger, level, message, _module, group, id, file, line; kwargs...)
    for (key,val) in pairs(kwargs)
        haskey(logger.components, key) ? logger.components[key] : add_component(logger, level, key)
        add_record(logger, level, key, val)
    end
end


function preprocess(exs)
    exs_interp = Expr[]
    for ex in exs
        if ex isa Expr && ex.head === :(=)
            k,v = ex.args
            push!(exs_interp, Expr(:(=), k, esc(v)))
        else
            throw(ArgumentError("No component tag found in `$ex`, use `tagname=$ex` instead!"))
        end
    end
    exs_interp
end

macro log_scalar(exs...) :(@logmsg ScalarLevel "" $(preprocess(exs)...)) end
macro log_histogram(exs...) :(@logmsg HistogramLevel "" $(preprocess(exs)...)) end
macro log_embedding(exs...) :(@logmsg EmbeddingLevel "" $(preprocess(exs)...)) end
macro log_text(exs...) :(@logmsg TextLevel "" $(preprocess(exs)...)) end
macro log_audio(exs...) :(@logmsg AudioLevel "" $(preprocess(exs)...)) end
macro log_image(exs...) :(@logmsg ImageLevel "" $(preprocess(exs)...)) end

_log_comp_docs = """
    @log_scalar [tag_name=(args...) | ...]
    @log_histogram [tag_name=(args...) | ...]
    @log_embedding [tag_name=(args...) | ...]
    @log_text [tag_name=(args...) | ...]
    @log_audio [tag_name=(args...) | ...]
    @log_image [tag_name=(args...) | ...]

Add a record to a component which has the `tag_name`. If the component is not initialized yet,
a new component will be created automatically with default arguments. For the detail of `args`
of each component, please read the [doc](http://visualdl.paddlepaddle.org/docs/develop/visualdl/en/api/write_logs.html)
"""

# Logging macros share documentation
@eval @doc $_log_comp_docs :(@log_scalar)
@eval @doc $_log_comp_docs :(@log_histogram)
@eval @doc $_log_comp_docs :(@log_embedding)
@eval @doc $_log_comp_docs :(@log_text)
@eval @doc $_log_comp_docs :(@log_audio)
@eval @doc $_log_comp_docs :(@log_image)