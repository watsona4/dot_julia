# License is MIT: https://github.com/JuliaString/HTML_Entities/LICENSE.md
#
# Mapping from HTML entities to the corresponding Unicode codepoint.

println("Running HTML entity build in ", pwd())

using StrTables

VER = UInt32(1)

const inpname = "htmlnames.jl"

include(inpname)

const disp = [false]

const fname = "html.dat"
const datapath = "../data"

const empty_str = ""

function make_tables()
    symnam = String[]
    symval = Vector{UInt32}[]

    for (nam, val) in htmlonechar
        push!(symnam, nam)
        push!(symval, [val])
    end
    for (nam, val) in htmlnonbmp
        push!(symnam, nam)
        push!(symval, [0x10000+val])
    end
    for (nam, val) in htmltwochar
        push!(symnam, nam)
        push!(symval, UInt32[val...])
    end

    # We want to build a table of all the names, sort them, then create a StrTable out of them
    srtnam = sortperm(symnam)
    srtval = symval[srtnam] # Values, sorted the same as srtnam

    # BMP characters
    l16 = Tuple{UInt16, UInt16}[]
    # non-BMP characters (in range 0x10000 - 0x1ffff)
    l32 = Tuple{UInt16, UInt16}[]
    # two characters packed into UInt32, first character in high 16-bits
    l2c = Tuple{UInt32, UInt16}[]

    for i in eachindex(srtnam)
        chrs = srtval[i]
        len = length(chrs)
        len > 2 && error("Too long sequence of characters $chrs")
        ch1 = chrs[1]
        if len == 2
            ch2 = chrs[end]
            (ch1 > 0x0ffff || ch2 > 0x0ffff) &&
                error("Character $ch1 or $ch2 > 0xffff")
            push!(l2c, (ch1<<16 | ch2, i))
        elseif ch1 > 0x1ffff
            error("Character $ch1 too large")
        elseif ch1 > 0x0ffff
            push!(l32, (ch1%UInt16, i))
        else
            push!(l16, (ch1%UInt16, i))
        end
    end

    # We now have 3 vectors, for single BMP characters, for non-BMP characters, and for 2 BMP chars
    # each has the value and a index into the name table
    # We need to create a vector the same size as the name table, that gives the index
    # of into one of the three tables, in order to go from names to 1 or 2 output characters
    # We also need, for each of the 3 tables, a sorted vector that goes from the indices
    # in each table to the index into the name table (so that we can find multiple names for
    # each character)

    indvec = create_vector(UInt16, length(srtnam))
    vec16, ind16, base32 = sortsplit!(indvec, l16, 0)
    vec32, ind32, base2c = sortsplit!(indvec, l32, base32)
    vec2c, ind2c, basefn = sortsplit!(indvec, l2c, base2c)

    (VER, string(now()), "loaded from $inpname",
     base32%UInt32, base2c%UInt32, StrTable(symnam[srtnam]), indvec,
     vec16, ind16, vec32, ind32, vec2c, ind2c)
end

savfile = joinpath(datapath, fname)
if isfile(savfile)
    println("Tables already exist")
else
    println("Creating tables")
    tup = nothing
    try
        global tup
        tup = make_tables()
    catch ex
        println(sprint(showerror, ex, catch_backtrace()))
    end
    println("Saving tables to ", savfile)
    StrTables.save(savfile, tup)
    println("Done")
end
