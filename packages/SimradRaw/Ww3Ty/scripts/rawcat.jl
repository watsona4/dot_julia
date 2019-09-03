#!/usr/bin/env julia

using SimradRaw

function main(args)
    for arg in args
        for datagram in datagrams(arg)
            println(datagram)
        end
    end
end


main(ARGS)
