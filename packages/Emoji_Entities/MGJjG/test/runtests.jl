using StrTables, Emoji_Entities

@static VERSION < v"0.7.0-DEV" ? (using Base.Test) : (using Test)

# Test the functions lookupname, matches, longestmatches, completions
# Check that characters from all 3 tables (BMP, non-BMP, string) are tested

const def = Emoji_Entities.default

@testset "Emoji_Entities" begin
@testset "lookupname" begin
    @test lookupname(def, SubString("My name is Spock", 12)) == ""
    @test lookupname(def, "foobar")   == ""
    @test lookupname(def, "sailboat") == "\u26f5"
    @test lookupname(def, "ring")     == "\U1f48d"
    @test lookupname(def, "flag-us")  == "\U1f1fa\U1f1f8"
end

@testset "matches" begin
    @test isempty(matches(def, ""))
    @test isempty(matches(def, "\u2020"))
    @test isempty(matches(def, SubString("This is \u2020", 9)))
    for (chrs, exp) in (("\u26f5", ["boat", "sailboat"]),
                        ("\U1f48d", ["ring"]),
                        ("\U1f596", ["spock-hand"]),
                        ("\U1f1fa\U1f1f8", ["flag-us", "us"]))
        res = matches(def, chrs)
        @test length(res) >= length(exp)
        @test intersect(res, exp) == exp
    end
end

@testset "longestmatches" begin
    @test isempty(longestmatches(def, "\u2020 abcd"))
    @test isempty(longestmatches(def, SubString("This is \U2020", 9)))
    for (chrs, exp) in (("\u26f5 abcd", ["boat", "sailboat"]),
                        ("\U1f48d abcd", ["ring"]),
                        ("\U1f1fa\U1f1f8 foo", ["flag-us", "us"]))
        res = longestmatches(def, chrs)
        @test length(res) >= length(exp)
        @test intersect(res, exp) == exp
    end
end

@testset "completions" begin
    @test isempty(completions(def, "ScottPaulJones"))
    @test isempty(completions(def, SubString("My name is Scott", 12)))
    for (chrs, exp) in (("al", ["alarm_clock", "alembic", "alien"]),
                        ("um", ["umbrella", "umbrella_on_ground", "umbrella_with_rain_drops"]))
        res = completions(def, chrs)
        @test length(res) >= length(exp)
        @test intersect(res, exp) == exp
    end
end
end
