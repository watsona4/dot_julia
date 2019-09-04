#
# server.jl --
#
# Implement XPA client methods.
#
#------------------------------------------------------------------------------
#
# This file is part of XPA.jl released under the MIT "expat" license.
# Copyright (C) 2016-2019, Éric Thiébaut (https://github.com/emmt/XPA.jl).
#

# We must make sure that the `send` and `recv` callbacks exist during the life
# of the server.  To that end, we use the following dictionary to maintain
# references to callbacks while they are used by an XPA server.
const _SERVERS = Dict{Ptr{Cvoid},Any}()

"""
```julia
Server(class, name, help, send, recv) -> srv
```

yields an XPA server identified by `class` and `name` (both specified as two
strings).

Argument `help` is a string which is meant to be returned by a help request
from `xpaget`:

```sh
xpaget class:name -help
```

Arguments `send` and `recv` are callbacks which will be called upon a client
[`XPA.get`](@ref) or [`XPA.set`](@ref) respectively.  At most one callback may
be `nothing`.

The send callback will be called in response to an external request from the
`xpaget` program, the `XPAGet()` or `XPAGetFd()` C routines, or the
[`XPA.get`](@ref) Julia method.  This callback is used to send data to the
requesting client and is a combination of a function (`sfunc` below) and
private data (`sdata` below) as summarized by the following typical example:

```julia
# Method to handle a send request:
function sfunc(sdata::S, srv::XPA.Server, params::String,
               bufptr::Ptr{Ptr{UInt8}}, lenptr::Ptr{Csize_t})
    result = ... # build up the result of the request
    try
        XPA.setbuf!(bufptr, lenptr, result)
        return XPA.SUCCESS
    catch err
        error(srv, err)
        return XPA.FAILURE
    end
end

# A send callback combines a method and some contextual data:
send = XPA.SendCallback(sfunc, sdata)
```

with `sdata` the client data (of type `S`) of the send callback, `srv` the XPA
server serving the request, `params` the parameter list of the `XPA.get` call,
`bufptr` and `lenptr` the addresses where to store the result of the request
and its size (in bytes).

The receive callback will be called in response to an external request from the
`xpaset` program, the `XPASet()` or `XPASetFd()` C routines, or the `XPA.set`
Julia method.  This callback is used to process send data to the requesting
client and is a combination of a function (`rfunc` below) and private data
(`rdata` below) as summarized by the following typical example:

```julia
# Method to handle a send request:
function rfunc(rdata::R, srv::XPA.Server, params::String,
               bufptr::Ptr{UInt8}, lenptr::Csize_t)
    println("receive: \$params")
    arr = unsafe_wrap(Array, buf, len, own=false)
    ...
    return XPA.SUCCESS
end

# A receive callback combines a method and some contextual data:
send = XPA.ReceiveCallback(rfunc, rdata)
```

with `rdata` the client data (of type `R`) of the receive callback, `srv` the
XPA server serving the request, `params` the parameter list of the `XPA.set`
call, `buf` and `len` the address and size (in bytes) of the data to process.

The callback methods `sfunc` and/or `rfunc` should return `XPA.SUCCESS` if no
error occurs, or `XPA.FAILURE` to signal an error.  The Julia XPA package takes
care of maintaining a reference on the client data and callback methods.

Also see: [`XPA.poll`](@ref), [`XPA.mainloop`](@ref), [`XPA.setbuf!`](@ref),
          [`XPA.SendCallback`](@ref), [`XPA.ReceiveCallback`](@ref).

"""
function Server(class::AbstractString,
                name::AbstractString,
                help::AbstractString,
                send::Union{SendCallback, Nothing},
                recv::Union{ReceiveCallback, Nothing})
    # Create an XPA server and a reference to the callback objects to make
    # sure they are not garbage collected while the server is running.
    server = Server(class, name, help,
                    _callback(send), _context(send), _mode(send),
	            _callback(recv), _context(recv), _mode(recv))
    _SERVERS[server.ptr] = (send, recv)
    return server
end

function Server(class::AbstractString, name::AbstractString,
                help::AbstractString,
                sproc::Ptr{Cvoid}, sdata::Ptr{Cvoid}, smode::AbstractString,
                rproc::Ptr{Cvoid}, rdata::Ptr{Cvoid}, rmode::AbstractString)
    ptr = ccall((:XPANew, libxpa), Ptr{Cvoid},
                (Cstring, Cstring, Cstring,
	         Ptr{Cvoid}, Ptr{Cvoid}, Cstring,
	         Ptr{Cvoid}, Ptr{Cvoid}, Cstring),
                class, name, help,
                sproc, sdata, smode,
                rproc, rdata, rmode)
    ptr != C_NULL || error("failed to create an XPA server")
    obj = finalizer(close, Server(ptr))
    (get_send_mode(obj) & MODE_FREEBUF) != 0 ||
        error("send mode must have `freebuf` option set")
    return obj
end

# The following methods are helpers to build instances of an XPA server.
_callback(::Nothing) = C_NULL
_callback(::SendCallback) = _SEND_REF[]
_callback(::ReceiveCallback) = _RECV_REF[]
_context(::Nothing) = C_NULL
_context(cb::Callback) = pointer_from_objref(cb)
_mode(::Nothing) = ""
_mode(cb::SendCallback) = "acl=$(cb.acl),freebuf=$(cb.freebuf)"
_mode(cb::ReceiveCallback) =
    "acl=$(cb.acl),buf=$(cb.buf),fillbuf=$(cb.fillbuf),freebuf=$(cb.freebuf)"

# The following method is called upon garbage collection of an XPA server.
function Base.close(srv::Server)
    if (ptr = srv.ptr) != C_NULL
        srv.ptr = C_NULL
        ccall((:XPAFree, libxpa), Cint, (Ptr{Cvoid},), ptr)
        haskey(_SERVERS, ptr) && pop!(_SERVERS, ptr)
    end
    return nothing
end

"""
```julia
SendCallback(func, data=nothing)
```

yields an instance of `SendCallback` for sending the data requested by a call
to `XPA.get` (or similar) to an XPA server.  Argument `func` is the method to
be called to process the request and optional argument `data` is some
associated contextual data.

Although keywords are available to tune the behavior of the server, not all
cases are currently managed, so it is recommended to keep the default values.

Also see: [`XPA.Server`](@ref), [`XPA.setbuf!`](@ref),
[`XPA.ReceiveCallback`](@ref).

"""
function SendCallback(func::Function,
                      data::T = nothing;
                      acl::Bool = true,
                      freebuf::Bool = true) where T
    SendCallback{T}(func, data, acl, freebuf)
end

"""
```julia
ReceiveCallback(func, data=nothing)
```

yields an instance of `ReceiveCallback` for processing the data sent
by a call to `XPA.set` (or similar) to an XPA server.  Argument `rfunc`
is the method to be called to process the request and optional argument
`data` is some associated contextual data.

Although keywords are available to tune the behavior of the server, not all
cases are currently managed, so it is recommended to keep the default values.

Also see: [`XPA.Server`](@ref), [`XPA.SendCallback`](@ref).

"""
function ReceiveCallback(func::Function,
                         data::T = nothing;
                         acl::Bool = true,
                         buf::Bool = true,
                         fillbuf::Bool = true,
                         freebuf::Bool = true) where T
    ReceiveCallback{T}(func, data, acl, buf, fillbuf, freebuf)
end

function _send(clientdata::Ptr{Cvoid}, handle::Ptr{Cvoid}, params::Ptr{Byte},
               bufptr::Ptr{Ptr{Byte}}, lenptr::Ptr{Csize_t})::Cint
    # Check assumptions.
    srv = Server(handle)
    (get_send_mode(srv) & MODE_FREEBUF) != 0 ||
        return error(srv, "send mode must have `freebuf` option set")

    # Call actual callback providing the client data is the address of a known
    # SendCallback object.
    return _send(unsafe_pointer_to_objref(clientdata), srv,
                 (params == C_NULL ? "" : unsafe_string(params)),
                 bufptr, lenptr)
end

function _send(cb::SendCallback, srv::Server, params::String,
               bufptr::Ptr{Ptr{Byte}}, lenptr::Ptr{Csize_t})
    return cb.send(cb.data, srv, params, bufptr, lenptr)
end

# The receive callback is executed in response to an external request from the
# `xpaset` program, the `XPASet()` routine, or `XPASetFd()` routine.
function _recv(clientdata::Ptr{Cvoid}, handle::Ptr{Cvoid}, params::Ptr{Byte},
               buf::Ptr{Byte}, len::Csize_t)::Cint
    # Call actual callback providing the client data is the address of a known
    # ReceiveCallback object.
    return _recv(unsafe_pointer_to_objref(clientdata), Server(handle),
                 (params == C_NULL ? "" : unsafe_string(params)), buf, len)
end

# If the receive callback mode has option `freebuf=false`, then `buf` must be
# managed by the callback, by default `freebuf=true` and the buffer is
# automatically released after callback completes.
function _recv(cb::ReceiveCallback, srv::Server, params::String,
               buf::Ptr{Byte}, len::Csize_t)
    return cb.recv(cb.data, srv, params, buf, len)
end

# Addresses of callbacks cannot be precompiled so we set them at run time in
# the __init__() method of the module.
const _SEND_REF = Ref{Ptr{Cvoid}}(0)
const _RECV_REF = Ref{Ptr{Cvoid}}(0)
function __init__()
    global _SEND_REF, _RECV_REF
    _SEND_REF[] = @cfunction(_send, Cint,
                             (Ptr{Cvoid},     # client_data
                              Ptr{Cvoid},     # call_data
                              Ptr{Byte},      # paramlist
                              Ptr{Ptr{Byte}}, # buf
                              Ptr{Csize_t}))  # len
    _RECV_REF[] = @cfunction(_recv, Cint,
                             (Ptr{Cvoid},     # client_data
                              Ptr{Cvoid},     # call_data
                              Ptr{Byte},      # paramlist
                              Ptr{Byte},      # buf
                              Csize_t))       # len
end

"""
```julia
error(srv, msg) -> XPA.FAILURE
```

communicates error message `msg` to the client when serving a request by XPA
server `srv`.  This method shall only be used by the send/receive callbacks of
an XPA server.

Also see: [`XPA.Server`](@ref), [`XPA.message`](@ref),
          [`XPA.SendCallback`](@ref), [`XPA.ReceiveCallback`](@ref).

"""
function Base.error(srv::Server, msg::AbstractString)
    ccall((:XPAError, libxpa), Cint, (Server, Cstring),
          srv, msg) == SUCCESS ||
              error("XPAError failed for message \"$msg\"");
    return FAILURE
end

"""
```julia
XPA.message(srv, msg)
```

sets a specific acknowledgment message back to the client. Argument `srv` is
the XPA server serving the client and `msg` is the acknowledgment message.
This method shall only be used by the receive callback of an XPA server.

Also see: [`XPA.Server`](@ref), [`XPA.error`](@ref),
          [`XPA.ReceiveCallback`](@ref).

"""
message(srv::Server, msg::AbstractString) =
    ccall((:XPAMessage, libxpa), Cint, (Server, Cstring), srv, msg)

"""
```julia
XPA.setbuf!(bufptr, lenptr, data)
```

or

```julia
XPA.setbuf!(bufptr, lenptr, buf, len)
```

set the values at addresses `bufptr` and `lenptr` to be the address and size of
a dynamically allocated buffer storing the contents of `data` (or a copy of the
`len` bytes at address `buf`).  This method is meant to be used in the *send*
callback to store the result of an `XPA.get` request processed by an XPA server

We are always assuming that the answer to a `XPA.get` request is a dynamically
allocated buffer which is deleted by `XPAHandler`.

See also: [`XPA.Server`](@ref), [`XPA.SendCallback`](@ref), [`XPA.get`](@ref).
"""
function setbuf!(bufptr::Ptr{Ptr{Byte}}, lenptr::Ptr{Csize_t},
                 ptr::Ptr{Byte}, len::Integer)
    # FIXME: We are always assuming that the answer to a XPAGet request is a
    #        dynamically allocated buffer which is deleted by `XPAHandler`.  We
    #        should make sure of that.

    # This function is similar to `XPASetBuf` except that it verifies that no
    # prior buffer has been set.
    (unsafe_load(bufptr) == NULL && unsafe_load(lenptr) == 0) ||
        error("setbuf! can be called only once")
    if ptr != NULL
        len > 0 || error("invalid number of bytes ($len) for non-NULL pointer")
        buf = _memcpy(_malloc(len), ptr, len)
        unsafe_store!(bufptr, buf)
        unsafe_store!(lenptr, len)
    else
        len == 0 || error("invalid number of bytes ($len) for NULL pointer")
    end
    return nothing
end

setbuf!(bufptr::Ptr{Ptr{Byte}}, lenptr::Ptr{Csize_t}, ::Nothing) =
    setbuf!(bufptr, lenptr, NULL, 0)

function setbuf!(bufptr::Ptr{Ptr{Byte}}, lenptr::Ptr{Csize_t},
                 val::Union{Symbol,AbstractString})
    return setbuf!(bufptr, lenptr, String(val))
end

setbuf!(bufptr::Ptr{Ptr{Byte}}, lenptr::Ptr{Csize_t}, str::String) =
    setbuf!(bufptr, lenptr, Base.unsafe_convert(Ptr{Byte}, str), sizeof(str))

function setbuf!(bufptr::Ptr{Ptr{Byte}}, lenptr::Ptr{Csize_t},
                 arr::DenseArray{T,N}) where {T, N}
    @assert isbitstype(T)
    setbuf!(bufptr, lenptr, convert(Ptr{Byte}, pointer(arr)), sizeof(arr))
end

function setbuf!(bufptr::Ptr{Ptr{Byte}}, lenptr::Ptr{Csize_t}, val::T) where {T}
    @assert isbitstype(T)
    (unsafe_load(bufptr) == NULL && unsafe_load(lenptr) == 0) ||
        error("setbuf! can be called only once")
    len = sizeof(T)
    buf = _malloc(len)
    unsafe_store!(convert(Ptr{T}, buf), val)
    unsafe_store!(bufptr, buf)
    unsafe_store!(lenptr, len)
    return nothing
end

"""
```julia
XPA.poll(sec, maxreq)
```

polls for XPA events.  This method is meant to implement a polling event loop
which checks for and processes XPA requests without blocking.

Argument `sec` specifies a timeout in seconds (rounded to millisecond
precision).  If `sec` is positive, the method blocks no longer than this amount
of time.  If `sec` is strictly negative, the routine blocks until the occurence
of an event to be processed.

Argument `maxreq` specifies how many requests will be processed.  If `maxreq <
0`, then no events are processed, but instead, the returned value indicates the
number of events that are pending.  If `maxreq == 0`, then all currently
pending requests will be processed.  Otherwise, up to `maxreq` requests will be
processed.  The most usual values for `maxreq` are `0` to process all requests
and `1` to process one request.

The following example implements a polling loop which has no noticeable impact
on the consumption of CPU when no requests are emitted to the server:

```julia
const running = Ref{Bool}(false)

function run()
    global running
    running[] = true
    while running[]
        XPA.poll(-1, 1)
    end
end
```

Here the global variable `running` is a reference to a boolean whose value
indicates whether to continue to run the XPA server(s) created by the process.
The idea is to pass the reference to the callbacks of the server (as their
client data for instance) and let the callbacks stop the loop by setting the
contents of the reference to `false`.

Another possibility is to use `XPA.mainloop` (which to see).

To let Julia performs other tasks, the polling method may be repeatedly called
by a Julia timer.  The following example does this.  Calling `resume` starts
polling for XPA events immediately and then every 100ms.  Calling `suspend`
suspends the processing of XPA events.

```julia
const __timer = Ref{Timer}()

ispolling() = (isdefined(__timer, 1) && isopen(__timer[]))

resume() =
    if ! ispolling()
        __timer[] = Timer((tm) -> XPA.poll(0, 0), 0.0, 0.1)
    end

suspend() =
    ispolling() && close(__timer[])
```


Also see: [`XPA.Server`](@ref), [`XPA.mainloop`](@ref).

"""
poll(sec::Real, maxreq::Integer) =
    ccall((:XPAPoll, libxpa), Cint, (Cint, Cint),
          (sec < 0 ? -1 : round(Cint, 1E3*sec)), maxreq)

"""
```julia
XPA.mainloop()
```

runs XPA event loop which handles the requests sent to the server(s) created by
this process.  The loop runs until all servers created by this process have
been closed.

In the following example, the receive callback function close the server when
it receives a `"quit"` command:

```julia
function rproc(::Nothing, srv::XPA.Server, params::String,
               buf::Ptr{UInt8}, len::Integer)
    status = XPA.SUCCESS
    if params == "quit"
        close(srv)
    elseif params == ...
        ...
    end
    return status
end
```

Also see: [`XPA.Server`](@ref), [`XPA.mainloop`](@ref).

"""
mainloop() =
    ccall((:XPAMainLoop, libxpa), Cint, ())
