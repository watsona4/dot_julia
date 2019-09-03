# License is MIT: LICENSE.md

using ModuleInterfaceTools

@api extend StrRegex

@static V6_COMPAT ? (using Base.Test) : (using Random, Unicode, Test)

const IndexError = isdefined(Base, :StringIndexError) ? StringIndexError : UnicodeError

# Add definitions not present in v0.6.2 for GenericString
@static if V6_COMPAT
    ncodeunits(s::GenericString) = ncodeunits(s.string)
    codeunit(s::GenericString) = codeunit(s.string)
    codeunit(s::GenericString, i::Integer) = codeunit(s.string, i)
end

cvt(v::Integer, m::Nothing) = v
cvt(v::Integer, m::Vector{Int}) = v < 1 ? v : m[v]
cvt(v::UnitRange, m) = cvt(v.start,m):cvt(v.stop,m)

# Should test GenericString also, once overthing else is working
const UnicodeStringTypes = (String, UTF8Str, UTF16Str, UTF32Str, UCS2Str)

const ASCIIStringTypes = (ASCIIStr, LatinStr, UTF8Str, UTF16Str, UTF32Str, UCS2Str, String)

function test2(str, list, umap::Any=nothing)
    mymap = (encoding(str) === encoding(UTF8Str) ? umap : nothing)
    for (pat, res) in list
        cvtres = cvt(res, mymap)
        (r = fnd(First, pat, str)) == cvtres ||
            println("fnd(First, $(typeof(pat)):\"$pat\", $(typeof(str)):\"$str\") => $r != $cvtres ($res)")
        @test fnd(First, pat, str) == cvtres
    end
end

function test3(str, list, umap::Any=nothing)
    mymap = encoding(str) == encoding(UTF8Str) ? umap : nothing
    for (pat, beg, res) in list
        cvtbeg = cvt(beg, mymap)
        cvtres = cvt(res, mymap)
        (r = fnd(Fwd, pat, str, cvtbeg)) == cvtres ||
            println("fnd(Fwd, $(typeof(pat)):\"$pat\", $(typeof(str)):\"$str\", $cvtbeg ($beg)) => $r != $cvtres ($res)")
        @test fnd(Fwd, pat, str, cvtbeg) == cvtres
    end
end

const fbbstr = "foo,bar,baz"
const astr = "Hello, world.\n"
const u8str = "∀ ε > 0, ∃ δ > 0: |x-y| < δ ⇒ |f(x)-f(y)| < ε"

# v0.6.2 returns a Vector{Any} for some reason, make sure it is converted to Vector{Int}
const utf8map = convert(Vector{Int}, collect(eachindex(u8str)))

@testset "ASCII Regex Tests" begin
    for T in ASCIIStringTypes
        fbb = T(fbbstr)
        str = T(astr)
        @testset "str: $T" begin
            # string forward search with a single-char regex
            let pats = (R"x", R"H", R"l", R"\n"),
                res  = (0:-1, 1:1, 3:3, 14:14)
                test2(str, zip(pats, res))
            end
            let pats = (R"H", R"l", R"l", R"l", R"\n"),
                pos  = (  2,    4,    5,   12,    14), # Was 15 for fndnext
                res  = (0:-1, 4:4,11:11, 0:-1, 14:14)
                test3(str, zip(pats, pos, res))
            end
            i = 1
            while i <= ncodeunits(str)
                @test fnd(Fwd, R"."s, str, i) == i:i
                # string forward search with a zero-char regex
                @test fnd(Fwd, R"", str, i) == i:i-1
                i = nextind(str, i)
            end
            let pats = (R"xx", R"fo", R"oo", R"o,", R",b", R"az"),
                res  = ( 0:-1,   1:2,   2:3,   3:4,   4:5, 10:11)
                test2(fbb, zip(pats, res))
            end
            let pats = (R"fo", R"oo", R"o,", R",b", R",b", R"az"),
                pos  = (    3,     4,     5,     6,    10,    11),
                res  = ( 0:-1,  0:-1,  0:-1,   8:9,  0:-1,  0:-1) # was 12 for fndnext
                test3(fbb, zip(pats, pos, res))
            end
        end
        rs = T("foo123 foo456 foo789")
        @testset "(starts|ends)_with: $T" begin
            @test startswith(rs, R"fo+\d+")
            @test endswith(rs, R"fo+\d+")
            @test !startswith(rs, R"f\d+")
            @test !endswith(rs, R"f\d+")
        end
    end
end

@testset "Unicode Regex Tests" begin
    for T in UnicodeStringTypes
        @testset "str: $T" begin
            str = T(u8str)
            @testset "Regex" begin
                let pats = (R"z", R"∄", R"∀", R"∃", R"x", R"ε"),
                    res  = (0:-1, 0:-1, 1:1, 10:10,20:20,  3:3)
                    test2(str, zip(pats, res), utf8map)
                end
                let pats = (R"∀", R"∃", R"x", R"x", R"ε", R"ε"),
                    pos  = (   2,   11,   21,   35,    4,   45), # was 56 for fndnext
                    res  = (0:-1, 0:-1,34:34, 0:-1,45:45,45:45)  # was 0:-1 for last
                    test3(str, zip(pats, pos, res), utf8map)
                end
                v = cvt(2, encoding(T) == encoding(UTF8Str) ? utf8map : nothing)
                @test fnd(First, R"∀", str)  == fnd(First, R"\u2200", str)
                @test fnd(Fwd, R"∀", str, v) == fnd(Fwd, R"\u2200", str, v)
                i = 1
                while i <= ncodeunits(str)
                    @test fnd(Fwd, R"."s, str, i) == i:i
                    # string forward search with a zero-char regex
                    @test fnd(Fwd, R"", str, i) == i:i-1
                    i = nextind(str, i)
                end
            end
        end
    end
end

const RegexStrings = (ASCIIStr, BinaryStr, Text1Str, LatinStr, _LatinStr, UTF8Str)

@static if V6_COMPAT
    collect_eachmatch(re, str; overlap=false) =
        [m.match for m in collect(eachmatch(re, str, overlap))]
else
    collect_eachmatch(re, str; overlap=false) =
        [m.match for m in collect(eachmatch(re, str, overlap = overlap))]
end

@testset "UTF8Str Regex" begin
    # Proper unicode handling
    @test match(R"∀∀", UTF8Str("∀x∀∀∀")).match == "∀∀"
    @test collect_eachmatch(R".\s", UTF8Str("x \u2200 x \u2203 y")) == ["x ", "∀ ", "x ", "∃ "]
end

@testset "Regex" begin
    for T in RegexStrings
        @test collect_eachmatch(R"a?b?", T("asbd")) == ["a","","b","",""] ==
            collect_eachmatch(R"""a?b?""", T("asbd"))
        @test collect_eachmatch(R"a?b?", T("asbd"), overlap=true) == ["a","","b","",""]
        @test collect_eachmatch(R"\w+", T("hello"), overlap=true) ==
            ["hello","ello","llo","lo","o"]
        @test collect_eachmatch(R"(\w+)(\s*)", T("The dark side of the moon")) ==
            ["The ", "dark ", "side ", "of ", "the ", "moon"]
        @test collect_eachmatch(R"", T("")) == [""]
        @test collect_eachmatch(R"", T(""), overlap=true) == [""]
        @test collect_eachmatch(R"aa", T("aaaa")) == ["aa", "aa"]
        @test collect_eachmatch(R"aa", T("aaaa"), overlap=true) == ["aa", "aa", "aa"]
        @test collect_eachmatch(R"", T("aaa")) == ["", "", "", ""]
        @test collect_eachmatch(R"", T("aaa"), overlap=true) == ["", "", "", ""]
        @test collect_eachmatch(R"GCG", T("GCGCG")) == ["GCG"]
        @test collect_eachmatch(R"GCG", T("GCGCG"),overlap=true) == ["GCG","GCG"]

# Issue 8278
target = """71.163.72.113 - - [30/Jul/2014:16:40:55 -0700] "GET emptymind.org/thevacantwall/wp-content/uploads/2013/02/DSC_006421.jpg HTTP/1.1" 200 492513 "http://images.search.yahoo.com/images/view;_ylt=AwrB8py9gdlTGEwADcSjzbkF;_ylu=X3oDMTI2cGZrZTA5BHNlYwNmcC1leHAEc2xrA2V4cARvaWQDNTA3NTRiMzYzY2E5OTEwNjBiMjc2YWJhMjkxMTEzY2MEZ3BvcwM0BGl0A2Jpbmc-?back=http%3A%2F%2Fus.yhs4.search.yahoo.com%2Fyhs%2Fsearch%3Fei%3DUTF-8%26p%3Dapartheid%2Bwall%2Bin%2Bpalestine%26type%3Dgrvydef%26param1%3D1%26param2%3Dsid%253Db01676f9c26355f014f8a9db87545d61%2526b%253DChrome%2526ip%253D71.163.72.113%2526p%253Dgroovorio%2526x%253DAC811262A746D3CD%2526dt%253DS940%2526f%253D7%2526a%253Dgrv_tuto1_14_30%26hsimp%3Dyhs-fullyhosted_003%26hspart%3Dironsource&w=588&h=387&imgurl=occupiedpalestine.files.wordpress.com%2F2012%2F08%2F5-peeking-through-the-wall.jpg%3Fw%3D588%26h%3D387&rurl=http%3A%2F%2Fwww.stopdebezetting.com%2Fwereldpers%2Fcompare-the-berlin-wall-vs-israel-s-apartheid-wall-in-palestine.html&size=49.0KB&name=...+%3Cb%3EApartheid+wall+in+Palestine%3C%2Fb%3E...+%7C+Or+you+go+peeking+through+the+%3Cb%3Ewall%3C%2Fb%3E&p=apartheid+wall+in+palestine&oid=50754b363ca991060b276aba291113cc&fr2=&fr=&tt=...+%3Cb%3EApartheid+wall+in+Palestine%3C%2Fb%3E...+%7C+Or+you+go+peeking+through+the+%3Cb%3Ewall%3C%2Fb%3E&b=0&ni=21&no=4&ts=&tab=organic&sigr=13evdtqdq&sigb=19k7nsjvb&sigi=12o2la1db&sigt=12lia2m0j&sign=12lia2m0j&.crumb=.yUtKgFI6DE&hsimp=yhs-fullyhosted_003&hspart=ironsource" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1985.125 Safari/537.36"""

        pat = R"""([\d\.]+) ([\w.-]+) ([\w.-]+) (\[.+\]) "([^"\r\n]*|[^"\r\n\[]*\[.+\][^"]+|[^"\r\n]+.[^"]+)" (\d{3}) (\d+|-) ("(?:[^"]|\")+)"? ("(?:[^"]|\")+)"?"""

        match(pat, T(target))

        # Issue 9545 (32 bit)
        buf = PipeBuffer()
        show(buf, R"")
        @static if V6_COMPAT
            @test readstring(buf) == "R\"\""
        else
            @test read(buf, String) == "R\"\""
        end

        # see #10994, #11447: PCRE2 allows NUL chars in the pattern
        @test occurs_in(Regex(T("^a\0b\$")), T("a\0b"))

        # regex match / search string must be a String
        @test_throws ArgumentError match(R"test", GenericString("this is a test"))
        @test_throws ArgumentError fnd(First, R"test", GenericString("this is a test"))

        # Named subpatterns
        let m = match(R"(?<a>.)(.)(?<b>.)", T("xyz"))
            @test (m[:a], m[2], m["b"]) == ("x", "y", "z")
            typ = T === _LatinStr ? ASCIIStr : T
            @test sprint(show, m) == "RegexStrMatch{$typ}(\"xyz\", a=\"x\", 2=\"y\", b=\"z\")"
        end
        # Backcapture reference in substitution string
        @static if V6_COMPAT
            @test replace(T("abcde"), R"(..)(?P<byname>d)", s"\g<byname>xy\\\1") == "adxy\\bce"
            @test_throws ErrorException replace(T("a"), R"(?P<x>)", s"\g<y>")
        else
            @test replace(T("abcde"), R"(..)(?P<byname>d)" => s"\g<byname>xy\\\1") == "adxy\\bce"
            @test_throws ErrorException replace(T("a"), R"(?P<x>)" => s"\g<y>")
        end
    end
end

for ST in UnicodeStringTypes
    @testset "$ST Regex Utility functions" begin
        foobarbaz = ST("foo,bar,baz")
        foo = ST("foo")
        bar = ST("bar")
        baz = ST("baz")
        abc = ST("abc")
        abcd = ST("abcd")
        @testset "rsplit/split" begin
            @test split(foobarbaz, R",") == [foo,bar,baz]

            let str = ST("a.:.ba..:..cba.:.:.dcba.:.")
                @test split(str, R"\.(:\.)+") == ["a","ba.",".cba","dcba",""]
                @test split(str, R"\.(:\.)+"; keepempty=false) == ["a","ba.",".cba","dcba"]
                @test split(str, R"\.+:\.+") == ["a","ba","cba",":.dcba",""]
                @test split(str, R"\.+:\.+"; keepempty=false) == ["a","ba","cba",":.dcba"]
            end

            # zero-width splits

            @test split(ST(""), R"") == [""]
            @test split(abc,  R"") == ["a","b","c"]
            @test split(abcd, R"b?") == ["a","c","d"]
            @test split(abcd, R"b*") == ["a","c","d"]
            @test split(abcd, R"b+") == ["a","cd"]
            @test split(abcd, R"b?c?") == ["a","d"]
            @test split(abcd, R"[bc]?") == ["a","","d"]
            @test split(abcd, R"a*") == ["","b","c","d"]
            @test split(abcd, R"a+") == ["","bcd"]
            @test split(abcd, R"d*") == ["a","b","c",""]
            @test split(abcd, R"d+") == [abc,""]
            @test split(abcd, R"[ad]?") == ["","b","c",""]
        end

        @testset "replace" begin
            @test replace(abcd, R"b?" => "^") == "^a^c^d^"
            @test replace(abcd, R"b+" => "^") == "a^cd"
            @test replace(abcd, R"b?c?" => "^") == "^a^d^"
            @test replace(abcd, R"[bc]?" => "^") == "^a^^d^"

            @test replace("foobarfoo", R"(fo|ba)" => "xx") == "xxoxxrxxo"
            @test replace("foobarfoo", R"(foo|ba)" => bar) == "barbarrbar"

            @test replace(ST("äƀçđ"), R"ƀ?" => "π") == "πäπçπđπ"
            @test replace(ST("äƀçđ"), R"ƀ+" => "π") == "äπçđ"
            @test replace(ST("äƀçđ"), R"ƀ?ç?" => "π") == "πäπđπ"
            @test replace(ST("äƀçđ"), R"[ƀç]?" => "π") == "πäππđπ"

            @test replace(ST("foobarfoo"), R"(fo|ba)" => "ẍẍ") == "ẍẍoẍẍrẍẍo"

            @test replace(ST("ḟøøbarḟøø"), R"(ḟø|ba)" => "xx") == "xxøxxrxxø"
            @test replace(ST("ḟøøbarḟøø"), R"(ḟøø|ba)" => bar) == "barbarrbar"

            @test replace(ST("fooƀäṙfoo"), R"(fo|ƀä)" => "xx") == "xxoxxṙxxo"
            @test replace(ST("fooƀäṙfoo"), R"(foo|ƀä)" => "ƀäṙ") == "ƀäṙƀäṙṙƀäṙ"

            @test replace(ST("ḟøøƀäṙḟøø"), R"(ḟø|ƀä)" => "xx") == "xxøxxṙxxø"
            @test replace(ST("ḟøøƀäṙḟøø"), R"(ḟøø|ƀä)" => "ƀäṙ") == "ƀäṙƀäṙṙƀäṙ"

            # for Char pattern call Char replacement function
            @test replace(ST("a"), R"a" => typeof) == "SubString{$ST}"
        end
    end
end
