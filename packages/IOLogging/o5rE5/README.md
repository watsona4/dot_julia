# IOLogging.jl

[![Build Status](https://travis-ci.com/Seelengrab/IOLogging.jl.svg?branch=master)](https://travis-ci.com/Seelengrab/IOLogging.jl)

A simple, thin package providing basic loggers for logging to IO. As the logging functionality from Base might change in the future, so will this package.

## Installation

This package is registered with METADATA.jl, so you can just do `]add IOLogging` to install the package.

## Usage

```julia
julia> using Logging, IOLogging

julia> logger = IOLogger()

julia> oldGlobal = global_logger(logger)

julia> @info "Hello World!"

# prints this (with a current timestamp):
# [Info::2018-09-12T10:50:12.884]  Main@REPL[4]:1 - Hello World!
```

We can also pass our own destinations for Logging:

```julia
# default is stdout for everything above Info
julia> logger = IOLogger(Dict(Logging.Info => stderr, Logging.Error => devnull))
```

The same as above applies to `FileLogger()` as well, but instead of giving destination IO, we specify a destination file.

```julia
# default is default.log for everything above Info
julia> logger = FileLogger(Dict(Logging.Info => "info.log", Logging.Error => "error.log"))
```

For more information about the individual loggers, make sure to read `?IOLogger` and `?FileLogger`.

## Known ToDo

 * Add custom log message formatting
 * Add more tests
 * Make decision on logging error catching (IOLogging.jl#20)
