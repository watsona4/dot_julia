# Syslogs
[![stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://invenia.github.io/Syslogs.jl/stable)
[![latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://invenia.github.io/Syslogs.jl/latest)
[![Build Status](https://travis-ci.org/invenia/Syslogs.jl.svg?branch=master)](https://travis-ci.org/invenia/Syslogs.jl)
[![codecov](https://codecov.io/gh/invenia/Syslogs.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/invenia/Syslogs.jl)

## Installation

```julia
Pkg.clone("https://github.com/invenia/Syslogs.jl")
```

## Usage

Syslogs.jl defines and exports a `Syslog` type which is a subtype of `IO`.

```julia
# Create our Syslog IO type which logs to the local syslog daemon via the libc interface.
io = Syslog()

# Print a log message to syslog of the form "<pri><msg>\0".
println(io, :info, "Hello World!")
```

To log to a remote server you can pass the remote ip address and port to the `Syslog` constructor. 

```julia
# Create our Syslog IO type which logs to a remote syslog service with the specified `ipaddr` and `port` via TCP.
io = Syslog(ipaddr, port; tcp=true)

# `log` is just and alias for `println` in this case.
log(io, :info, "Hello World!")
```

Several `IO` methods exist for the `Syslog` type:

```julia
println(io::Syslogs.Syslog, level::Symbol, msg::String)
println(io::Syslogs.Syslog, level::AbstractString, msg::AbstractString)
log(io::Syslogs.Syslog, args...)
close(io::Syslogs.Syslog)
flush(io::Syslogs.Syslog)
```

Syslogs.jl also provides several methods to the [libc interface](https://www.gnu.org/software/libc/manual/html_node/Submitting-Syslog-Messages.html#Submitting-Syslog-Messages):

```julia
Syslogs.openlog(ident::String, logopt::Integer, facility::Integer)
Syslogs.syslog(priority::Integer, msg::String)
Syslogs.closelog()
Syslogs.makepri(facility::Integer, priority::Integer)   # maps to the LOG_MAKEPRI macro
```

## TODO

- TLS support with MbedTLS.jl
