using StrTables, Unicode_Entities

@static VERSION < v"0.7.0-DEV" ? (using Base.Test) : (using Test)

# Test the functions lookupname, matches, longestmatches, completions
# Check that characters from all 3 tables (BMP, non-BMP, 2 character) are tested

const def = Unicode_Entities.default

const datapath = "../data"
const dpath = "ftp://ftp.unicode.org/Public/UNIDATA/"
const fname = "UnicodeData.txt"

const symnam = Vector{String}()
const symval = Vector{Char}()

"""Load up all names and characters from original data file"""
function load_unicode_data()
    lname = joinpath(datapath, fname)
    isfile(lname) || download(string(dpath, fname), lname)
    aliasnam = Vector{String}()
    aliasval = Vector{Char}()
    open(lname, "r") do f
        while (l = chomp(readline(f))) != ""
            flds = split(l, ";")
            str = flds[2]
            alias = flds[11]
            ch = Char(parse_hex(UInt32, flds[1]))
            if str[1] == '<'
                str != "<control>" && continue
                str = ""
            end
            if str != ""
                push!(symnam, str)
                push!(symval, ch)
            end
            if alias != ""
                push!(aliasnam, alias)
                push!(aliasval, ch)
            end
        end
    end
    # Check for duplicates
    names = Set{String}(symnam)
    for (str,ch) in zip(aliasnam, aliasval)
        if !(str in names)
            push!(symnam, str)
            push!(symval, ch)
        end
    end
end

load_unicode_data()

@testset "Unicode_Entities" begin

    @testset "matches data file" begin
        for (i, ch) in enumerate(symval)
            list = matchchar(def, ch)
            if !isempty(list)
                @test symnam[i] in list
            end
        end
        for (i, nam) in enumerate(symnam)
            str = lookupname(def, nam)
            if str != ""
                @test symval[i] == str[1]
            end
        end
    end
        
@testset "lookupname" begin
    @test lookupname(def, "foobar")   == ""
    @test lookupname(def, SubString("My name is Spock", 12)) == ""
    @test lookupname(def, "end of text") == "\x03" # \3
    @test lookupname(def, "TIBETAN LETTER -A") == "\u0f60"
    @test lookupname(def, "LESS-THAN OR SLANTED EQUAL TO") == "\u2a7d"
    @test lookupname(def, "REVERSED HAND WITH MIDDLE FINGER EXTENDED") == "\U1f595"
end

@testset "matches" begin
    @test isempty(matches(def, ""))
    @test isempty(matches(def, "\uf900"))
    @test isempty(matches(def, SubString("This is \uf900", 9)))
    for (chrs, exp) in (("\U1f596", ["RAISED HAND WITH PART BETWEEN MIDDLE AND RING FINGERS"]),
                        ("\u0f4a", ["TIBETAN LETTER REVERSED TA"]),
                        (".", ["FULL STOP", "PERIOD"]))
        res = matches(def, chrs)
        @test length(res) >= length(exp)
        @test intersect(res, exp) == exp
    end
end

@testset "longestmatches" begin
    @test isempty(longestmatches(def, "\uf900 abcd"))
    @test isempty(longestmatches(def, SubString("This is \uf900 abcd", 9)))
    for (chrs, exp) in (("\U1f596 abcd", ["RAISED HAND WITH PART BETWEEN MIDDLE AND RING FINGERS"]),
                        (".abcd", ["FULL STOP", "PERIOD"]),
                        ("\u0f4a#123", ["TIBETAN LETTER REVERSED TA", "TIBETAN LETTER TTA"]))
        res = longestmatches(def, chrs)
        @test length(res) >= length(exp)
        @test intersect(res, exp) == exp
    end
end

@testset "completions" begin
    @test isempty(completions(def, "ScottPaulJones"))
    @test isempty(completions(def, SubString("My name is Scott", 12)))
    for (chrs, exp) in (("ZERO", ["ZERO WIDTH JOINER", "ZERO WIDTH NO-BREAK SPACE",
                                  "ZERO WIDTH NON-JOINER", "ZERO WIDTH SPACE"]),
                        ("BACK OF", ["BACK OF ENVELOPE"]))
        res = completions(def, chrs)
        @test length(res) >= length(exp)
        @test intersect(res, exp) == exp
    end
end
end

