#!/usr/bin/env julia

using Filetimes

# Command line programming for converting DateTimes and Filetimes,
# e.g.
# ./filetime.jl 2018-07-19T18:26:00.766
# ./filetime.jl 131764980100450000
# ./filetime.jl

function main(args)

    if length(args) > 0
        x = args[1]
        y = tryparse(Int64,x)
        if isnull(y)
            println("$x\t$(filetime(x))")
        else
            println("$(datetime(get(y)))\t$x")
        end
    else
        x = now()
        println("$x\t$(filetime(x))")
    end
end


main(ARGS)
