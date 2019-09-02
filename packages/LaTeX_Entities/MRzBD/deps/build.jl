# License is MIT: https://github.com/JuliaString/LaTeX_Entities/LICENSE.md
#
# Portions of this are based on code from julia/base/latex_symbols.jl
#
# Mapping from LaTeX math symbol to the corresponding Unicode codepoint.
# This is used for tab substitution in the REPL.

println("Running LaTeX build in ", pwd())

using LightXML
using StrTables

VER = UInt32(1)

#const dpath = "http://www.w3.org/Math/characters/"
const dpath = "http://www.w3.org/2003/entities/2007xml/"
const fname = "unicode.xml"
#const lpath = "http://mirror.math.ku.edu/tex-archive/macros/latex/contrib/unicode-math/"
const lpath = "https://raw.githubusercontent.com/wspr/unicode-math/master/"
const lname = "unicode-math-table.tex"

const disp = [false]

# Get manual additions to the tables
include("../src/manual_latex.jl")

const datapath = "../data"

const empty_str = ""
const element_types = ("mathlatex", "AMS", "IEEE", "latex")

function get_math_symbols(dpath, fname)
    lname = joinpath(datapath, fname)
    if isfile(fname)
        println("Loaded: ", lname)
        vers = lname
    else
        vers = string(dpath, fname)
        download(vers, lname)
        println("Saved to: ", lname)
    end
    xdoc = parse_file(lname)

    latex_sym  = [Pair{String, String}[] for i = 1:length(element_types)]

    info = Tuple{Int, Int, String, String, String}[]
    count = 0
    # Handle differences in versions of unicode.xml document
    rt = root(xdoc)
    top = find_element(rt, "charlist")
    top == nothing || (rt = top)
    for c in child_nodes(rt)
        if name(c) == "character" && is_elementnode(c)
            ce = XMLElement(c)
            for (ind, el) in enumerate(element_types)
                latex = find_element(ce, el)
                if latex == nothing
                    disp[] && println("##\t", attribute(ce, "id"), "\t", ce)
                    continue
                end
                L = strip(content(latex))
                id = attribute(ce, "id")
                U = string(map(s -> Char(parse_hex(UInt32, s)), split(id[2:end], "-"))...)
                mtch = _contains(L, r"^\\[A-Za-z][A-Za-z0-9]*(\{[A-Za-z0-9]\})?$")
                disp[] &&
                    println("#", count += 1, "\t", mtch%Int, " id: ", id, "\tU: ", U, "\t", L)
                if mtch
                    L = L[2:end] # remove initial \
                    if length(U) == 1 && isascii(U[1])
                        # Don't store LaTeX names for ASCII characters
                        typ = 0
                    else
                        typ = 1
                        push!(latex_sym[ind], String(L) => U)
                    end
                    push!(info, (ind, typ, L, U, empty_str))
                end
            end
        end
    end
    latex_sym, vers, info
end

function add_math_symbols(dpath, fname)
    lname = joinpath(datapath, fname)
    if isfile(fname)
        println("Loaded: ", lname)
        vers = lname
    else
        vers = string(dpath, fname)
        download(vers, lname)
        println("Saved to: ", lname)
    end
    latex_sym = Pair{String, String}[]
    info = Tuple{Int, Int, String, String, String}[]
    open(lname) do f
        for L in eachline(f)
            (isempty(L) || L[1] == '%') && continue
            x = map(s -> rstrip(s, [' ','\t','\n']),
                    split(_replace(L, r"[{}\"]+" => "\t"), "\t"))
            ch = Char(parse_hex(UInt32, x[2]))
            nam = String(x[3][2:end])
            startswith(nam, "math") && (nam = nam[5:end])
            if isascii(ch)
                typ = 0 # ASCII
            elseif Base.is_id_char(ch)
                typ = 1 # identifier
            elseif Base.isoperator(Symbol(ch))
                typ = 2 # operator
            else
                typ = 3
            end
            typ != 0 && push!(latex_sym, nam => string(ch))
            push!(info, (2, typ, nam, string(ch), x[5]))
        end
    end
    latex_sym, vers, info
end

#=

 standard | v7.0    | new   | type
----------|---------|-------|-------------------------------
mscr	  | scr	    | c_    | script/cursive
msans	  | sans    | s_    | sans-serif
Bbb       | bb	    | d_    | blackboard / doublestruck
mfrak     | frak    | f_    | fraktur
mtt	  | tt	    | t_    | mono
mit	  | it	    | i_    | italic
mitsans   | isans   | is_   | italic sans-serif
mitBbb    | bbi	    | id_   | italic blackboard / doublestruct
mbf	  | bf	    | b_    | bold
mbfscr	  | bscr    | bc_   | bold script/cursive
mbfsans   | bsans   | bs_   | bold sans-serif
mbffrak   | bfrak   | bf_   | bold fraktur
mbfit	  | bi	    | bi_   | bold italic
mbfitsans | bisans  | bis_  | bold italic sans-serif
<greek>             | G     | greek
it<greek>           | i_G   | italic greek
bf<greek>           | b_G   | bold greek
bi<greek>	    | bi_G  | bold italic greek
bsans<greek>	    | bs_G  | bold sans-serif greek
bisans<greek>       | bis_G | bold italic sans-serif greek
var<greek>          | V     | greek variant
mitvar<greek>       | i_V   | italic greek variant
mbfvar<greek>       | b_V   | bold greek variant
mbfitvar<greek>	    | bi_V  | bold italic greek variant
mbfsansvar<greek>   | bs_V  | bold sans-serif greek variant
mbfitsansvar<greek> | bis_V | bold italic sans-serif greek variant

i -> imath                     ı
=#
function str_chr(val)
    isempty(val) && return ""
    io = IOBuffer()
    for ch in val
        print(io, hex(ch%UInt32,4), ':')
    end
    String(take!(io))[1:end-1]
end

function str_names(nameset)
    io = IOBuffer()
    allnames = sort(collect(nameset))
    for n in allnames
        print(io, n, " ")
    end
    String(take!(io))
end

function add_name(dic::Dict, val, nam)
    if haskey(dic, val)
        push!(dic[val], nam)
        disp[] && println("\e[s$val\e[u\e[4C$(rpad(str_chr(val),20))", str_names(dic[val]))
    else
        dic[val] = Set((nam,))
        disp[] && println("\e[s$val\e[u\e[4C$(rpad(str_chr(val),20))$nam")
    end
end

function check_name(out::Dict, dic::Dict, val, nam, old)
    oldval = get(dic, nam, "")
    # Check if short name is already in table with same value
    oldval == "" && return (add_name(out, val, nam); true)
    oldval != val && disp[] && println("Conflict: $old => $val, $nam => $oldval")
    false
end

function replace_suffix(out, dic, val, nam, suffix, pref, list)
    for (suf, rep) in list
        suffix == suf && return check_name(out, dic, val, pref * rep, nam)
    end
    false
end

#=
function replace_greek(out, dic, val, nam, off, pref, list)
    for (suf, rep) in list
        if nam[off:end] == suf
            return check_name(out, dic, val, pref * rep, nam) |
                   check_name(out, dic, val, pref[1:end-1] * suf, nam)
        end
    end
    false
end
=#

function replace_all(out, dic, val, nam, suffix, pref)
#    replace_greek(out, dic, val, nam, off, pref * "G_", greek_letters) ||
#    replace_greek(out, dic, val, nam, off, pref * "V_", var_greek) ||
    replace_suffix(out, dic, val, nam, suffix, pref * "_", digits)
end

function shorten_names(names::Dict)
    valtonam = Dict{String,Set{String}}()
    for (nam, val) in names
        # handle combining accents, change from 'accent{X}' to 'X-accent'
        if !startswith(nam, "math") && sizeof(nam) > 3 &&
            nam[end]%UInt8 == '}'%UInt8 && nam[end-2]%UInt8 == '{'%UInt8
            ch = nam[end-1]%UInt8
            if ch - 'A'%UInt8 < 0x1a || ch - 'a'%UInt8 < 0x1a || ch - '0'%UInt8 < 0xa
                # tst = string(nam[end-1], '-', nam[1:end-3])
                # check_name(valtonam, names, val, tst, nam)
                add_name(valtonam, val, nam)
                continue
            end
        end
        # Special handling of "up"/"mup" prefixes
        if startswith(nam, "up")
            # Add it later when processing "mup" prefix if they have the same value
            get(names, "m" * nam, "") == val && continue
        elseif startswith(nam, "mup")
            # If short form in table with same value, continue, otherwise, add short form
            #upval = get(names, nam[2:end], "") # see if "up..." is in the table
            #val == upval && continue # short name is already in table with same value
            oldval = get(names, nam[4:end], "") # see if "..." is in the table
            val == oldval && continue # short name is already in table with same value
            check_name(valtonam, names, val, oldval == "" ? nam[4:end] : nam[2:end], nam)
            continue
        else
            flg = false
            nam in remove_name && continue
            for (oldnam, newnam) in replace_name
                if nam == oldnam
                    flg = check_name(valtonam, names, val, newnam, nam)
                    break
                end
            end
            flg && continue
            if nam[1] in remove_lead_char
                for pref in remove_prefix
                    startswith(nam, pref) || continue
                    flg = true
                    tst = nam[sizeof(pref)+1:end]
                    oldval = get(names, tst, "")
                    oldval == val || (oldval == "" && add_name(valtonam, val, tst))
                    break
                end
            elseif nam[1] in replace_lead_char
                for (pref, rep, repv7) in replace_prefix
                    startswith(nam, pref) || continue
                    suff = nam[sizeof(pref)+1:end]
                    flg = replace_all(valtonam, names, val, nam, suff, rep)
                    #=
                    if rep == "i"
                        flg = replace_all(valtonam, names, val, suff, "i")
                    elseif rep == "t" || rep == "d" || rep == "s" || rep == "c"
                        flg = replace_all(valtonam, names, val, suff, rep)
                    elseif rep == "" || rep[1] != 'b'
                    elseif rep == "b"
                        flg = replace_all(valtonam, names, val, suff, "b")
                    elseif rep == "sb"
                        flg = replace_all(valtonam, names, val, suff, "bs")
                    elseif rep == "ib"
                        flg = replace_all(valtonam, names, val, suff, "bi")
                    elseif rep == "cib"
                        flg = replace_all(valtonam, names, val, suff, "bic")
                    end
                    =#
                    flg || (flg = check_name(valtonam, names, val, rep * "_" * suff, nam))
                    #check_name(valtonam, names, val, repv7 * nam[sizeof(pref)+1:end], nam)
                    #flg = true
                    break
                end
            end
            # Add short forms, if not already handled
            flg && continue
        end
#            replace_suffix(valtonam, names, val, nam, 1, "G_", greek_letters) ||
#                replace_suffix(valtonam, names, val, nam, 1, "V_", var_greek)
        add_name(valtonam, val, nam)
    end
    # Split into two vectors
    syms = Vector{String}()
    vals = Vector{String}()
    for (val, namset) in valtonam
        for nam in namset
            startswith(nam, "math") && length(namset) > 1 && continue
            push!(syms, nam)
            push!(vals, val)
        end
    end
    syms, vals
end

function make_tables()
    sym1, ver1, inf1 = get_math_symbols(dpath, fname)
    sym2, ver2, inf2 = add_math_symbols(lpath, lname)

    latex_sym = [mansym..., sym1[1], sym2, sym1[2:end]...]
    et = (mantyp..., element_types[1], "tex", element_types[2:end]...)

    latex_set = Dict{String,String}()
    diff_set = Dict{String,Set{String}}()

    # Select the first name found, ignore duplicates
    for (ind, sym_set) in enumerate(latex_sym)
        countdup = 0
        countdiff = 0
        for (nam, val) in sym_set
            old = get(latex_set, nam, "")
            if old == ""
                push!(latex_set, nam => val)
            elseif val == old
                countdup += 1
            else
                countdiff += 1
                if haskey(diff_set, nam)
                    push!(diff_set[nam], val)
                else
                    push!(diff_set, nam => Set([old, val]))
                end
            end
        end
        println(countdup, " duplicates, ", countdiff, " overwritten out of ", length(sym_set),
                " found in ", et[ind])
    end
    # Dump out set
    disp[] && println("LaTeX set:\n", latex_set)
    disp[] && println("Differences:\n", diff_set)

    # Now, replace or remove prefixes and suffixes
    symnam, symval = shorten_names(latex_set)

    disp[] && println(length(symval), " distinct entities found\n", symnam)
    
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
        ch1 = chrs[1]%UInt32
        if len == 2
            ch2 = chrs[end]%UInt32
            (ch1 > 0x0ffff || ch2 > 0x0ffff) &&
                error("Character $ch1 or $ch2 > 0xffff")
            push!(l2c, (ch1<<16 | ch2, i))
        elseif ch1 > 0x1ffff
            error("Character $ch1 too large")
        elseif ch1 > 0x0ffff
            push!(l32, (ch1-0x10000, i))
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

    ((VER, string(now()), string(ver1, ",", ver2),
      base32%UInt32, base2c%UInt32, StrTable(symnam[srtnam]), indvec,
      vec16, ind16, vec32, ind32, vec2c, ind2c),
     (ver1, ver2), (inf1, inf2))
end

savfile = joinpath(datapath, "latex.dat")
if isfile(savfile)
    println("Tables already exist")
else
    tup = nothing
    println("Creating tables")
    try
        global tup
        tup = make_tables()
    catch ex
        println(sprint(showerror, ex, catch_backtrace()))
    end
    println("Saving tables to ", savfile)
    StrTables.save(savfile, tup[1])
    println("Done")
end
