using JSON
using StrTables

const VER = UInt32(1)

const inpname = "emoji_pretty.json"
const vers  = "master" # Julia used 0f0cf4ea8845eb52d26df2a48c3c31c3b8cad14e
const dpath = "https://raw.githubusercontent.com/iamcal/emoji-data/"

const fname = "emoji.dat"
const datapath = "../data"

const disp = [false]

# Get manual additions to the tables
include("../src/manual_emoji.jl")

str_to_uint32(str) = UInt32[ch%UInt32 for ch in str]

function make_tables(dpath, ver, fname)
    lname = joinpath(datapath, fname)
    if isfile(lname)
        println("Loaded: ", lname)
        src = lname
    else
        src = string(dpath, ver, '/', fname)
        download(src, lname)
        println("Saved to: ", lname)
    end
    emojidata = JSON.parsefile(lname)

    mandict = Dict(manual)
    symnam = String[ n for (n, v) in manual ]
    symval = Vector{UInt32}[ str_to_uint32(v) for (n, v) in manual ]
    ind = 0
    for emoji in emojidata
        # Make a vector of Chars out of hex data
        unified = emoji["unified"]
        unistr = UInt32[parse_hex(UInt32, str) for str in split(unified,'-')]
        strval = String(Char.(unistr))
        vecnames = emoji["short_names"]
        for name in vecnames
            manval = get(mandict, name, "")
            if manval == ""
                disp[] && println('#', ind += 1, '\t', unified, '\t', name)
                push!(symnam, name)
                push!(symval, unistr)
            else
                println(name, " => ", strval, "  overridden by manual entry: ", manval)
            end
        end
    end
    disp[] && println()

    # Get emoji names sorted
    srtnam = sortperm(symnam)
    srtval = symval[srtnam]

    # BMP characters
    l16 = Tuple{UInt16, UInt16}[]
    # non-BMP characters (in range 0x10000 - 0x1ffff)
    l32 = Tuple{UInt16, UInt16}[]
    # Vector of characters
    l2c = Tuple{String, UInt16}[]

    max2c = 1
    for i in eachindex(srtnam)
        chrs = srtval[i]
        len = length(chrs)
        if len > 1
            max2c = max(max2c, len)
            push!(l2c, (String(Char[ch for ch in chrs]), i))
        else
            ch = chrs[1]
            if ch > 0x1ffff
                error("Character $ch too large")
            elseif ch > 0x0ffff
                push!(l32, (ch%UInt16, i))
            else
                push!(l16, (ch%UInt16, i))
            end
        end
    end

    # We now have 3 vectors, for single BMP characters, for non-BMP characters, and for strings
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

    (VER, string(now()), src,
     base32%UInt32, base2c%UInt32, StrTable(symnam[srtnam]), indvec,
     vec16, ind16, vec32, ind32, StrTable(vec2c), ind2c, max2c%UInt32)
end

savfile = joinpath(datapath, fname)
if isfile(savfile)
    println("Tables already exist")
else
    tup = nothing
    println("Creating tables")
    try
        global tup
        tup = make_tables(dpath, vers, inpname)
    catch ex
        println(sprint(showerror, ex, catch_backtrace()))
    end
    println("Saving tables to ", savfile)
    StrTables.save(savfile, tup)
    println("Done")
end
