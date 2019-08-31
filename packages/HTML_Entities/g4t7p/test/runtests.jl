using StrTables, HTML_Entities

@static VERSION < v"0.7.0-DEV" ? (using Base.Test) : (using Test)

# Test the functions lookupname, matches, longestmatches, completions
# Check that characters from all 3 tables (BMP, non-BMP, string) are tested

const def = HTML_Entities.default

@testset "HTML_Entities" begin
@testset "lookupname" begin
    @test lookupname(def, SubString("My name is Spock", 12)) == ""
    @test lookupname(def, "foobar") == ""
    @test lookupname(def, "nle")    == "\u2270"
    @test lookupname(def, "Pscr")   == "\U1d4ab"
    @test lookupname(def, "lvnE")   == "\u2268\ufe00"
end

@testset "matches" begin
    @test isempty(matches(def, ""))
    @test isempty(matches(def, "\u201f"))
    @test isempty(matches(def, SubString("This is \u201f", 9)))
    for (chrs, exp) in (("\u2270", ["nle", "nleq"]),
                        ("\U1d4ab", ["Pscr"]),
                        ("\U1d51e", ["afr"]),
                        ("\u2268\ufe00", ["lvertneqq", "lvnE"]))
        res = matches(def, chrs)
        @test length(res) >= length(exp)
        @test intersect(res, exp) == exp
    end
end

@testset "longestmatches" begin
    @test isempty(longestmatches(def, "\u201f abcd"))
    @test isempty(longestmatches(def, SubString("This is \U201f abcd", 9)))
    for (chrs, exp) in (("\u2270 abcd", ["nle", "nleq"]),
                        ("\U1d4ab abcd", ["Pscr"]),
                        ("\u2268\ufe00 silly", ["lvertneqq", "lvnE"]))
        res = longestmatches(def, chrs)
        @test length(res) >= length(exp)
        @test intersect(res, exp) == exp
    end
end

@testset "completions" begin
    @test isempty(completions(def, "ScottPaulJones"))
    @test isempty(completions(def, SubString("My name is Scott", 12)))
    for (chrs, exp) in (("and", ["and", "andand", "andd", "andslope", "andv"]),
                        ("um", ["umacr", "uml"]))
        res = completions(def, chrs)
        @test length(res) >= length(exp)
        @test intersect(res, exp) == exp
    end
end
end
