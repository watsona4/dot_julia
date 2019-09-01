# EnhancedLogging.jl
[![Build Status](https://travis-ci.com/adamslc/EnhancedLogging.jl.svg?branch=master)](https://travis-ci.com/adamslc/EnhancedLogging.jl)

Extends and improves the Julia language's built in `ConsoleLogger`.
Additionally adds a `WorkerLogger` that passes log records to the main process
before processing them.

## Install
```julia
pkg> add EnhancedLogging
```

## Usage
To setup enhanced logging on all running processes, put the following *after*
all worker processes have been started:
```julia
@everywhere using Logging, EnhancedLogging
global_logger(EnhancedConsoleLogger())
@everywhere global_logger(WorkerLogger(global_logger()))
```
This will setup an `EnhancedLogger` on the master process, and `WorkerLogger`s
on the workers.

## Limitations
Currently, the worker logging only works with global loggers, i.e. using
`with_logger` will prevent the log message from being forwarded to the master
process. This is mostly due to a limitation in how pointers are serialized for
interprocess communication. If you have ideas about how to circumvent this
problem, please open an issue so that we can discuss.
