exists(lib::Ptr, sym::Symbol) = Libdl.dlsym_e(lib, sym) != C_NULL

function udp_srv(port::Int)
    r = Future()

    sock = UDPSocket()
    bind(sock, ip"127.0.0.1", port)

    @async begin
        put!(r, String(recv(sock)))
        close(sock)
    end

    return r
end

function tcp_srv(port::Int)
    r = Future()

    server = listen(ip"127.0.0.1", port)
    @async begin
        while !isready(r)
            sock = accept(server)
            put!(r, readuntil(sock, '\0'; keep=true))
        end
        close(server)
    end

    return r
end
