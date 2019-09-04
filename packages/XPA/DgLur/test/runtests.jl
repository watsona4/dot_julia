#
# runtests.jl --
#
# Exercises XPA communication in Julia.
#
#------------------------------------------------------------------------------
#
# This file is part of XPA.jl released under the MIT "expat" license.
# Copyright (C) 2016-2017, Éric Thiébaut (https://github.com/emmt/XPA.jl).
#
module XPATests

using XPA
import Base: RefValue

const VERBOSE = false

function sproc1(running::RefValue{Bool}, srv::XPA.Server, params::String,
                bufptr::Ptr{Ptr{UInt8}}, lenptr::Ptr{Csize_t})
    if running[]
        VERBOSE && println("send: $params")
        result = 42
        try
            XPA.setbuf!(bufptr, lenptr, result)
            return XPA.SUCCESS
        catch err
            error(srv, err)
            return XPA.FAILURE
        end
    end
end

function rproc1(running::RefValue{Bool}, srv::XPA.Server, params::String,
                buf::Ptr{UInt8}, len::Integer)

    status = XPA.SUCCESS
    if running[]
        VERBOSE && println("receive: $params [$len byte(s)]")
        #arr = unsafe_wrap(Array, buf, len, own=false)
        if params == "quit"
            running[] = false
        elseif params == "greetings"
            status = XPA.message(srv, "hello folks!")
        end
    end
    return status
end

function main1()
    running = Ref(true)
    server = XPA.Server("TEST", "test1", "help me!",
                        XPA.SendCallback(sproc, running),
                        XPA.ReceiveCallback(rproc1, running))
    while running[]
        XPA.poll(-1, 1)
    end
    close(server)
end

function sproc2(::Nothing, srv::XPA.Server, params::String,
                bufptr::Ptr{Ptr{UInt8}}, lenptr::Ptr{Csize_t})
    VERBOSE && println("send: $params")
    result = 42
    try
        XPA.setbuf!(bufptr, lenptr, result)
        return XPA.SUCCESS
    catch err
        error(srv, err)
        return XPA.FAILURE
    end
end

function rproc2(::Nothing, srv::XPA.Server, params::String,
                buf::Ptr{UInt8}, len::Integer)

    status = XPA.SUCCESS
    if params == "quit"
        close(srv)
    elseif params == "greetings"
        status = XPA.message(srv, "hello folks!")
    end
    return status
end

function main2()
    server = XPA.Server("TEST", "test1", "help me!",
                        XPA.SendCallback(sproc2, nothing),
                        XPA.ReceiveCallback(rproc2, nothing))
    XPA.mainloop()
end


end
