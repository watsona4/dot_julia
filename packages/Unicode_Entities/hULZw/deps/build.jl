# License is MIT: https://github.com/JuliaString/Unicode_Entities/LICENSE.md

using StrTables

const VER = UInt32(1)

const datapath = "../data"
const dpath = "https://www.unicode.org/Public/UCD/latest/ucd/"
const inpname = "UnicodeData.txt"
const fname = "unicode.dat"
const disp = [false]

const _empty_string = ""
const _empty_val = (false, ' ', _empty_string, _empty_string)

function process_line(vec::Vector{T}) where {T<:AbstractString}
    length(vec) < 11 && return _empty_val
    num = vec[1]
    str = vec[2]
    alias = vec[11]
    ch = parse_hex(UInt32, num)
    str[1] == '<' &&
        return str == "<control>" ? (alias != "", ch, _empty_string, alias) : _empty_val
    # Don't save names that simply contain hex representation
    len = length(num)
    pos = sizeof(str) - len
    pos > 1 && str[pos] == '-' && str[pos+1:end] == num && return _empty_val
    # Check for some characters we won't represent, all outside of BMP range
    ch <= 0x0ffff && return (true, ch, str, alias)
    # Ignore characters in Linear B range (0x10000-0x100ff)
    0x10000 <= ch < 0x10100 && return _empty_val
    # Ignore characters in Linear A range (0x10600-0x107ff)
    0x10600 <= ch < 0x10800 && return _empty_val
    # Ignore characters in hieroglyph range (0x13000-0x14fff)
    0x13000 <= ch < 0x15000 && return _empty_val
    # Ignore characters in Tangut range (0x17000-0x18fff)
    0x17000 <= ch < 0x19000 && return _empty_val
    # Ignore characters in Greek vocal/instrumental range (0x1d200-0x1d2ff)
    0x1d000 <= ch < 0x1d300 && return _empty_val
    # Don't worry about characters outside of BMP/SMP1
    ch > 0x1FFFF && return _empty_val
    (true, ch, str, alias)
end

function load_unicode_data(datapath, dpath, fname)
    lname = joinpath(datapath, fname)
    if isfile(lname)
        println("Loading Unicode Data: ", lname)
        src = lname
    else
        src = string(dpath, fname)
        println("Downloading Unicode Data: ", src)
        download(src, lname)
        println("Saved to: ", lname)
    end
    symnam = String[]
    symval = UInt32[]
    aliasnam = String[]
    aliasval = UInt32[]
    count = lines = aliascnt = 0
    open(lname, "r") do f
        while (l = chomp(readline(f))) != ""
            lines += 1
            flg, ch, str, alias = process_line(split(l, ";"))
            disp[] && println('#', lines, '\t', Int(flg), " ", l)
            flg || continue
            if symnam != ""
                count += 1
                push!(symnam, str)
                push!(symval, ch)
            end
            if alias != ""
                aliascnt += 1
                push!(aliasnam, alias)
                push!(aliasval, ch)
            end
        end
    end
    # Check for duplicates
    names = Set{String}(symnam)
    dupcnt = 0
    for (str,ch) in zip(aliasnam, aliasval)
        if str in names
            dupcnt += 1
        else
            push!(symnam, str)
            push!(symval, ch)
        end
    end
    println("Removed ",dupcnt," duplicate aliases")
    println("Finished loading ", count, " + ", aliascnt-dupcnt, " entities on ", lines, " lines")
    symnam, symval, src
end

function split_tables(srtval)
    # BMP characters
    l16 = Tuple{UInt16, UInt16}[]
    # non-BMP characters (in range 0x10000 - 0x1ffff)
    l32 = Tuple{UInt16, UInt16}[]

    for (i, ch) in enumerate(srtval)
        ch > 0x1ffff && error("Character $ch too large")
        push!(ch > 0x0ffff ? l32 : l16, (ch%UInt16, i))
    end

    # We now have 2 vectors, one for single BMP characters, the other for SMP-1 characters
    # each has the value and a index into the name table
    # We need to create a vector the same size as the name table, that gives the index
    # into one of the tables, in order to go from names to the output character
    # We also need, for each of the tables, a sorted vector that goes from the indices
    # in each table to the index into the name table (so that we can find multiple names for
    # each character)

    indvec = create_vector(UInt16, length(srtval))
    vec16, ind16, base32 = sortsplit!(indvec, l16, 0)
    vec32, ind32, base2c = sortsplit!(indvec, l32, base32)

    base32%UInt32, indvec, vec16, ind16, vec32, ind32
end

function update_map!(wrdmap, inp, off, wrd_vec, wrd_dict)
    wrd = wrd_vec[inp]
    srt = sortperm(wrd)
    tab = inp[srt]
    map = wrd_vec[tab]
    for (i, v) in enumerate(map)
        wrdmap[wrd_dict[v]] = (i+off)%UInt16
    end
    map
end

function create_map(wrd_vec, wrd_dict, tab1, tab2)
    wrdmap = zeros(UInt16, length(wrd_vec))
    map1 = update_map!(wrdmap, tab1,  53, wrd_vec, wrd_dict)
    map2 = update_map!(wrdmap, tab2, 255, wrd_vec, wrd_dict)
    wrdmap, map1, map2
end

keepword(str) = !_contains(str, r"^[A-Z0-9\-]+$")

function outseg!(out, str)
    for ch in str
        push!(out, ch == '-' ? 0x01 : (ch%UInt8 - ((ch-'0')<=9 ? 0x2e : 0x35)))
    end
end

function packword(inpvec::Vector, wrdmap, wrd_vec, wrd_dict)
    out = UInt8[]
    hasparts = false
    prevw = 0x0000
    for val16 in inpvec
        w = wrdmap[val16]
        if w > 0x00ff
            push!(out, ((w>>>8)+37)%UInt8, w%UInt8)
        elseif w != 0x0000
            push!(out, w%UInt8)
        else
            str = wrd_vec[val16]
            !isempty(out) && (prevw < 0x26 || str[1] == '-') && push!(out, 0x00)
            if '-' in str
                parts = split(str, '-')
                hasparts = true
                disp[] && print(parts)
                len = length(parts)
                for pos = 1:len
                    seg = parts[pos]
                    if (pwrd = get(wrd_dict, seg, 0)) == 0 || (wp = wrdmap[pwrd]) == 0
                        outseg!(out, seg)
                    elseif wp > 0x00ff
                        push!(out, ((wp>>>8)+37)%UInt8, wp%UInt8)
                    else
                        push!(out, wp%UInt8)
                    end
                    pos != len && push!(out, 0x01)
                end
            else
                outseg!(out, str)
            end
        end
        prevw = w
    end
    hasparts && disp[] && println("\t",out)
    out
end

function split_words(input::Vector{<:AbstractString})
    wrd_dict = Dict{String, Int}()
    wrd_vec  = String[]
    wrd_frq  = Int[]
    wrd_loc  = UInt16[]
    str_vec  = create_vector(Vector{UInt16}, length(input))
    #=
    part_dic = Dict{String, Int}()
    part_vec = String[]
    part_frq = Int[]
    wrd_parts = Vector{UInt16}[]
    =#
    ind = 0
    for (i, wrd) in enumerate(input)
        allwrds = split(wrd, ' ')
        outwrds = UInt16[]
        for onewrd in allwrds
            val = get(wrd_dict, onewrd, 0)
            if val == 0
                val = (ind += 1)
                disp[] && println(val, '\t', i, '\t', onewrd)
                push!(wrd_vec, onewrd)
                push!(wrd_frq, 0)
                push!(wrd_loc, i) # location first found (may be only location)
                wrd_dict[onewrd] = val
                if '-' in onewrd
                    allparts = split(onewrd, '-')
                    for part in allparts
                        part == "" && continue
                        if (vp = get(wrd_dict, part, 0)) == 0
                            vp = (ind += 1)
                            disp[] && println("\tparts:\t", vp, '\t', i, '\t', part)
                            push!(wrd_vec, part)
                            push!(wrd_frq, 0)
                            push!(wrd_loc, i) # location first found (may be only location)
                            wrd_dict[part] = vp
                        end
                        wrd_frq[vp] += 1
                    end
                end
            end
            wrd_frq[val] += 1
            push!(outwrds, val)
        end
        str_vec[i] = outwrds
    end

    # Calculate the savings of each word, i.e. frequency * (length-1), where freq > 1
    # take top 256-(16+38) = 202 words
    wrdsav = sort([((wrd_frq[i]-1)*(sizeof(wrd_vec[i])-1), i)
                   for i = 1:length(wrd_vec) if wrd_frq[i]>1 || keepword(wrd_vec[i])],
                  rev=true)
    # This has indexes into wrd_vec for words that will end up as 1-byte
    table1 = [wrdsav[i][2] for i=1:202]
    # This has indexes into wrd_vec for words that will end up as 2-bytes
    table2 = [wrdsav[i][2] for i=203:length(wrdsav)]
    # Calculate the savings of remaining words, i.e. frequency * (length-2) (some will become 0)
    savfrq = Int[]
    savval = UInt16[]
    for i in table2
        savings = (wrd_frq[i]-1)*(sizeof(wrd_vec[i])-2)
        if savings > 2 || keepword(wrd_vec[i])
            push!(savfrq, savings)
            push!(savval, i)
        end
    end

    # For every word in wrd_vec, create an entry to that has 0-37, 38-53, 54-255, 256-and above
    wrd_map, map1, map2 = create_map(wrd_vec, wrd_dict, table1, savval)

    # Pack words
    ent_map = create_vector(Vector{UInt8}, length(str_vec))
    for (i, vec16) in enumerate(str_vec)
	ent_map[i] = packword(vec16, wrd_map, wrd_vec, wrd_dict)
    end
    PackedTable(ent_map), StrTable(map1), StrTable(map2)
end

function make_tables(datapath, dpath, fname)
    symnam, symval, src = load_unicode_data(datapath, dpath, fname)
    srtind = sortperm(symnam)
    srtnam = symnam[srtind]
    srtval = symval[srtind]
    entmap, map1, map2 = split_words(srtnam)
    base32, indvec, vec16, ind16, vec32, ind32 = split_tables(srtval)
    (VER, string(now()), src, base32, entmap, indvec, map1, map2, vec16, ind16, vec32, ind32)
end

savfile = joinpath(datapath, fname)
if isfile(savfile)
    println("Tables already exist")
else
    tup = nothing
    println("Creating tables")
    try
        global tup
        tup = make_tables(datapath, dpath, inpname)
    catch ex
        println(sprint(showerror, ex, catch_backtrace()))
    end
    println("Saving tables to ", savfile)
    StrTables.save(savfile, tup)
    println("Done")
end
