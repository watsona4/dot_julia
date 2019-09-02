using Dates

function write_oeis_bfile(anum, range, seq, comments, targetdir)

    if !occursin(r"^A[0-9]{6}$", anum)
        @warn("Not a valid A-number! Exiting.")
        return
    end

    filename = joinpath(targetdir, "b" * anum[2:end] * ".txt")
    @info("Writing " * anum * " to " * filename)

    file = open(filename, "w")
    timestamp = Dates.format(now(), "yyyy-mm-dd HH:MM")
    println(file, "# ", timestamp)
    for c in comments
        println(file, "# ", c)
    end

    for n in range
        val = seq(n)
        if length(string(val)) > 1000
            @error("Term too long, exiting.")
            break
        end
        println(file, n, " ", val)
    end
    close(file)
end

path = "C:/Users/Home/JuliaProjects/IntegerSequences/data"

# Example use:
comments = ["Author: Julia Verona",
           "The divergent series par excellence."]
a(n) = factorial(BigInt(n))
R = 11:200
write_oeis_bfile("A000142", R, a, comments, path)

# Example use:
write_oeis_bfile("A000290", 0:100, n -> n * n, "", path)
