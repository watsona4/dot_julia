#
# types.jl --
#
# Type definitions for XPA package.
#
#------------------------------------------------------------------------------
#
# This file is part of XPA.jl released under the MIT "expat" license.
# Copyright (C) 2016-2019, Éric Thiébaut (https://github.com/emmt/XPA.jl).
#

const Byte = UInt8
const NULL = Ptr{Byte}(0)

"""

`XPA.SUCCESS` and `XPA.FAILURE` are the possible values returned by the
callbacks of an XPA server.

"""
const SUCCESS = convert(Cint,  0)
const FAILURE = convert(Cint, -1)
@doc @doc(SUCCESS) FAILURE

# Server mode flags for receive, send, info.
const MODE_BUF     = convert(Cint, 1)
const MODE_FILLBUF = convert(Cint, 2)
const MODE_FREEBUF = convert(Cint, 4)
const MODE_ACL     = convert(Cint, 8)

# Super type for client and server XPA objects.
abstract type Handle end

# XPA client, must be mutable to be finalized.
mutable struct Client <: Handle
    ptr::Ptr{Cvoid} # pointer to XPARec structure
end

# XPA server, must be mutable to be finalized.
mutable struct Server <: Handle
    ptr::Ptr{Cvoid} # pointer to XPARec structure
end

abstract type Callback end

struct SendCallback{T} <: Callback
    send::Function # function to call on `XPAGet` requests
    data::T        # client data
    acl::Bool      # enable access control
    freebuf::Bool  # free buf after callback completes
end

struct ReceiveCallback{T} <: Callback
    recv::Function # function to call on `XPASet` requests
    data::T        # client data
    acl::Bool      # enable access control
    buf::Bool      # server expects data bytes from client
    fillbuf::Bool  # read data into buffer before executing callback
    freebuf::Bool  # free buffer after callback completes
end

struct AccessPoint
    class::String # class of the access point
    name::String  # name of the access point
    addr::String  # socket access method (host:port for inet,
                  # file for local/unix)
    user::String  # user name of access point owner
    access::UInt  # allowed access
end

# Singleton to represent a NULL-buffer.
struct NullBuffer end
