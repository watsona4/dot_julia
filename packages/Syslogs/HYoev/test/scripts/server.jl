sock = UDPSocket()
bind(sock, ip"127.0.0.1", 8080)
open("output.log", "w") do f
    while true
        info("Receiving data...")
        s = String(recv(sock))
        info(s)
        write(f, s)
    end
end
close(sock)