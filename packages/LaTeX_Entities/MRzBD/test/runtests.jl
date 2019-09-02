using StrTables, LaTeX_Entities

@static VERSION < v"0.7.0-DEV" ? (using Base.Test) : (using Test)

const def = LaTeX_Entities.default

# Test the functions lookupname, matches, longestmatches, completions
# Check that characters from all 3 tables (BMP, non-BMP, 2 character) are tested

@testset "LaTeX_Entities" begin

@testset "lookupname" begin
    @test lookupname(def, SubString("My name is Spock", 12)) == ""
    @test lookupname(def, "foobar")   == ""
    @test lookupname(def, "dagger")   == "†" # \u2020
    #@test lookupname(def, "mscrl")    == "𝓁" # \U1f4c1
    @test lookupname(def, "c_l")       == "𝓁" # \U1f4c1
    @test lookupname(def, "nleqslant") == "⩽̸" # \u2a7d\u338
end

@testset "matches" begin
    @test isempty(matches(def, ""))
    @test isempty(matches(def, "\U1f596"))
    @test isempty(matches(def, SubString("My name is \U1f596", 12)))
    for (chrs, exp) in (("√", ["sqrt", "surd"]),
                        #("𝓁", ["mscrl"]),
                        ("𝓁", ["c_l"]),
                        ("⩽̸", ["nleqslant"]))
        res = matches(def, chrs)
        @test length(res) >= length(exp)
        @test intersect(res, exp) == exp
    end
end

@testset "longestmatches" begin
    @test isempty(longestmatches(def, "\U1f596 abcd"))
    @test isempty(longestmatches(def, SubString("My name is \U1f596", 12)))
    for (chrs, exp) in (("√abcd", ["sqrt", "surd"]),
                        #("𝓁abcd", ["mscrl"]),
                        ("𝓁abcd", ["c_l"]),
                        ("⩽̸abcd", ["nleqslant"]))
        res = longestmatches(def, chrs)
        @test length(res) >= length(exp)
        @test intersect(res, exp) == exp
    end
end

@testset "completions" begin
    @test isempty(completions(def, "ScottPaulJones"))
    @test isempty(completions(def, SubString("My name is Scott", 12)))
    for (chrs, exp) in (("A", ["AA", "AE", "Alpha"]),
                        #("mtt", ["mtta", "mttthree", "mttzero"]),
                        ("varp", ["varperspcorrespond", "varphi", "varpi"]),
                        ("nleq", ["nleq", "nleqslant"]))
        res = completions(def, chrs)
        @test length(res) >= length(exp)
        @test intersect(res, exp) == exp
    end
end
end
