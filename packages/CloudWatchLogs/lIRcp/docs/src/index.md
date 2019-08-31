# CloudWatchLogs

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://invenia.github.io/CloudWatchLogs.jl/stable)
[![Latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://invenia.github.io/CloudWatchLogs.jl/latest)
[![Build Status](https://travis-ci.com/invenia/CloudWatchLogs.jl.svg?branch=master)](https://travis-ci.com/invenia/CloudWatchLogs.jl)
[![CodeCov](https://codecov.io/gh/invenia/CloudWatchLogs.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/invenia/CloudWatchLogs.jl)

CloudWatchLogs.jl provides easy access to CloudWatch Log Streams, and provides a [Memento](https://github.com/invenia/Memento.jl) log handler.

## Usage

### Direct

CloudWatchLogs.jl uses [AWSCore.jl](https://github.com/JuliaCloud/AWSCore.jl/) for authentication and communication with Amazon Web Services.
Many functions accept a `config::AWSConfig` parameter, which can be retrieved from AWSCore's `aws_config` function.

CloudWatch Log Streams can be created and deleted by name using [`create_stream`](@ref) and [`delete_stream`](@ref).
Those streams (or previously-existing streams) can be wrapped in a [`CloudWatchLogStream`](@ref).

[`LogEvent`](@ref)s are simply string messages and timestamps. By default, the timestamp is the current time. You can submit `LogEvent`s to a `CloudWatchLogStream` using [`submit_logs`](@ref) or [`submit_log`](@ref).

Here is an example:

```julia
using CloudWatchLogs
using AWSCore

config = aws_config()
stream = CloudWatchLogStream(
    config, "existing-log-group", create_stream("my-stream-$(uuid1())")
)
submit_log(stream, LogEvent("Hello, I'm a log"))
submit_logs(stream, [LogEvent("I'm log #$i") for i in 1:3])
```

### With Memento

#### Single Process

CloudWatchLogs.jl also provides a log [handler](https://invenia.github.io/Memento.jl/stable/man/handlers.html) for [Memento.jl](https://github.com/invenia/Memento.jl).

To add a handler to the root logger:

```julia
push!(getlogger("root"), CloudWatchLogHandler(aws_config(), "my-log-group", "my-log-stream"))
```

Or, to add a handler to a package's logger:

```julia
# in the package's root module
const LOGGER = getlogger(@__MODULE__)

function __init__()
    Memento.register(LOGGER)
    push!(LOGGER, CloudWatchLogHandler(aws_config(), "my-log-group", "my-log-stream"))
end
```

#### Parallel Usage

Only one source can log to a CloudWatch Log Stream at a time, as each log submission must be submitted with the previous submission's sequence token.
With Memento, this means you need a stream and handler for each process you will be logging to your logger from.

To add a handler with a unique stream to the root logger on each process:

```julia
@everywhere using Memento
@everywhere using UUIDs
@everywhere push!(getlogger("root"), CloudWatchLogHandler(aws_config(), "my-log-group", "my-log-stream-$(uuid1())"))
```

Or, to add a handler to a package's logger which will generate a new stream for each process it's loaded on:

```julia
# in the package's root module
const LOGGER = getlogger(@__MODULE__)

function __init__()
    Memento.register(LOGGER)
    push!(LOGGER, CloudWatchLogHandler(aws_config(), "my-log-group", "my-log-stream-$(uuid1())"))
end
```
